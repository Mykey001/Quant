import { Router, type IRouter, type Request, type Response } from "express";
import multer from "multer";
import { db, strategiesTable, analysisRunsTable, stepResultsTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { runAnalysisPipeline } from "../lib/analysis-pipeline.js";

const router: IRouter = Router();
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ["mq5", "mql4", "pine", "py", "txt", "js", "ts", "cs"];
    const ext = file.originalname.split(".").pop()?.toLowerCase() ?? "";
    if (allowed.includes(ext) || file.mimetype.startsWith("text/")) {
      cb(null, true);
    } else {
      cb(new Error(`File type not supported: .${ext}`));
    }
  },
});

function detectFileType(filename: string): string {
  const ext = filename.split(".").pop()?.toLowerCase() ?? "";
  if (ext === "mq5") return "mq5";
  if (ext === "mql4") return "mql4";
  if (ext === "pine" || filename.toLowerCase().includes("pine")) return "pine";
  if (ext === "py") return "python";
  return "other";
}

router.get("/strategies", async (req: Request, res: Response) => {
  try {
    const strategies = await db.select().from(strategiesTable).orderBy(strategiesTable.createdAt);
    res.json(strategies.map(s => ({
      ...s,
      fileType: s.fileType,
    })));
  } catch (err) {
    req.log.error({ err }, "Failed to list strategies");
    res.status(500).json({ error: "internal_error", message: "Failed to list strategies" });
  }
});

router.post("/strategies", upload.single("file"), async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: "bad_request", message: "No file uploaded" });
      return;
    }

    const fileContent = req.file.buffer.toString("utf-8");
    const fileName = req.file.originalname;
    const fileType = detectFileType(fileName);
    const name = (req.body.name as string) || fileName;
    const description = (req.body.description as string) || "";

    const [strategy] = await db
      .insert(strategiesTable)
      .values({ name, description, fileType, fileName, fileContent })
      .returning();

    res.status(201).json(strategy);
  } catch (err) {
    req.log.error({ err }, "Failed to upload strategy");
    res.status(500).json({ error: "internal_error", message: "Failed to upload strategy" });
  }
});

router.get("/strategies/:id", async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id);
    const [strategy] = await db.select().from(strategiesTable).where(eq(strategiesTable.id, id));

    if (!strategy) {
      res.status(404).json({ error: "not_found", message: "Strategy not found" });
      return;
    }
    res.json(strategy);
  } catch (err) {
    req.log.error({ err }, "Failed to get strategy");
    res.status(500).json({ error: "internal_error", message: "Failed to get strategy" });
  }
});

router.delete("/strategies/:id", async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id);
    await db.delete(strategiesTable).where(eq(strategiesTable.id, id));
    res.status(204).send();
  } catch (err) {
    req.log.error({ err }, "Failed to delete strategy");
    res.status(500).json({ error: "internal_error", message: "Failed to delete strategy" });
  }
});

router.post("/strategies/:id/analyze", async (req: Request, res: Response) => {
  try {
    const strategyId = parseInt(req.params.id);
    const [strategy] = await db.select().from(strategiesTable).where(eq(strategiesTable.id, strategyId));

    if (!strategy) {
      res.status(404).json({ error: "not_found", message: "Strategy not found" });
      return;
    }

    const options = {
      markets: req.body?.markets ?? ["XAUUSD"],
      timeframes: req.body?.timeframes ?? ["H1", "D1"],
      yearsOfData: req.body?.yearsOfData ?? 10,
      trainSplit: req.body?.trainSplit ?? 0.7,
      validationSplit: req.body?.validationSplit ?? 0.15,
    };

    const [run] = await db
      .insert(analysisRunsTable)
      .values({ strategyId, status: "pending", totalSteps: 10, options })
      .returning();

    const stepInserts = Array.from({ length: 10 }, (_, i) => ({
      runId: run.id,
      stepNumber: i + 1,
      stepName: [
        "Strategy Deconstruction",
        "Data Collection & Preparation",
        "Baseline Backtest",
        "Market Regime Segmentation",
        "Model Training & Adaptation",
        "Parameter Optimization",
        "Validation (Out-of-Sample)",
        "Walk-Forward Analysis",
        "Risk & Failure Analysis",
        "Final Output & Recommendations",
      ][i],
      status: "pending" as const,
    }));

    await db.insert(stepResultsTable).values(stepInserts);

    setImmediate(() => {
      runAnalysisPipeline(run.id, strategy.fileContent, strategy.fileType).catch(() => {
        db.update(analysisRunsTable)
          .set({ status: "failed", errorMessage: "Pipeline failed unexpectedly", updatedAt: new Date() })
          .where(eq(analysisRunsTable.id, run.id))
          .catch(() => {});
      });
    });

    res.status(202).json({
      ...run,
      options,
    });
  } catch (err) {
    req.log.error({ err }, "Failed to start analysis");
    res.status(500).json({ error: "internal_error", message: "Failed to start analysis" });
  }
});

export default router;
