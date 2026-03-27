import { Router, type IRouter, type Request, type Response } from "express";
import { db, analysisRunsTable, stepResultsTable } from "@workspace/db";
import { eq } from "drizzle-orm";

const router: IRouter = Router();

router.get("/runs", async (req: Request, res: Response) => {
  try {
    const runs = await db.select().from(analysisRunsTable).orderBy(analysisRunsTable.createdAt);
    res.json(runs);
  } catch (err) {
    req.log.error({ err }, "Failed to list runs");
    res.status(500).json({ error: "internal_error", message: "Failed to list runs" });
  }
});

router.get("/runs/:id", async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id);
    const [run] = await db.select().from(analysisRunsTable).where(eq(analysisRunsTable.id, id));

    if (!run) {
      res.status(404).json({ error: "not_found", message: "Run not found" });
      return;
    }
    res.json(run);
  } catch (err) {
    req.log.error({ err }, "Failed to get run");
    res.status(500).json({ error: "internal_error", message: "Failed to get run" });
  }
});

router.get("/runs/:id/steps", async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id);
    const steps = await db
      .select()
      .from(stepResultsTable)
      .where(eq(stepResultsTable.runId, id))
      .orderBy(stepResultsTable.stepNumber);

    res.json(steps);
  } catch (err) {
    req.log.error({ err }, "Failed to get run steps");
    res.status(500).json({ error: "internal_error", message: "Failed to get run steps" });
  }
});

export default router;
