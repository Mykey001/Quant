import { Router } from "express";
import multer from "multer";
import { db } from "@workspace/db";
import { datasetsTable } from "@workspace/db/schema";
import { eq } from "drizzle-orm";

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

// ─── CSV Parser ────────────────────────────────────────────────────────────────
function parseCSV(text: string): { headers: string[]; rows: Record<string, string>[] } {
  const lines = text.split(/\r?\n/).filter(l => l.trim().length > 0);
  if (lines.length === 0) return { headers: [], rows: [] };

  // Detect delimiter
  const firstLine = lines[0];
  const delimiter = firstLine.includes("\t") ? "\t" : firstLine.includes(";") ? ";" : ",";

  const headers = firstLine.split(delimiter).map(h => h.trim().replace(/^["']|["']$/g, ""));
  const rows: Record<string, string>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(delimiter).map(v => v.trim().replace(/^["']|["']$/g, ""));
    if (values.length < headers.length) continue;
    const row: Record<string, string> = {};
    headers.forEach((h, idx) => { row[h] = values[idx] ?? ""; });
    rows.push(row);
  }

  return { headers, rows };
}

function parseJSON(text: string): { headers: string[]; rows: Record<string, string>[] } {
  const data = JSON.parse(text);
  const arr = Array.isArray(data) ? data : data.data ?? data.ohlcv ?? data.bars ?? [];
  if (arr.length === 0) return { headers: [], rows: [] };
  const headers = Object.keys(arr[0]);
  const rows = arr.map((r: Record<string, unknown>) => {
    const row: Record<string, string> = {};
    headers.forEach(h => { row[h] = String(r[h] ?? ""); });
    return row;
  });
  return { headers, rows };
}

// ─── Stats Helpers ─────────────────────────────────────────────────────────────
function computeColumnStats(headers: string[], rows: Record<string, string>[]) {
  return headers.map(name => {
    const values = rows.map(r => r[name]);
    const nums = values.map(Number).filter(n => !isNaN(n) && n !== null);
    const nullCount = values.filter(v => v === "" || v == null).length;

    if (nums.length === 0) return { name, min: null, max: null, mean: null, std: null, nullCount };

    const min = Math.min(...nums);
    const max = Math.max(...nums);
    const mean = nums.reduce((a, b) => a + b, 0) / nums.length;
    const variance = nums.reduce((a, b) => a + (b - mean) ** 2, 0) / nums.length;
    const std = Math.sqrt(variance);

    return { name, min: +min.toFixed(6), max: +max.toFixed(6), mean: +mean.toFixed(6), std: +std.toFixed(6), nullCount };
  });
}

// Detect the date column heuristically
function detectDateColumn(headers: string[]): string | null {
  const dateKeywords = ["date", "time", "datetime", "timestamp", "Date", "Time", "DateTime"];
  return headers.find(h => dateKeywords.some(k => h.toLowerCase().includes(k.toLowerCase()))) ?? null;
}

// Detect asset name from columns or file name
function detectAsset(fileName: string, headers: string[]): string | null {
  const assetCol = headers.find(h => /^(asset|symbol|ticker|pair|instrument)/i.test(h));
  if (assetCol) return null; // let data specify it row-by-row
  // Try to extract from filename: e.g. XAUUSD_H1.csv
  const match = fileName.match(/^([A-Z]{3,8})(?:_|\.|-)/);
  return match ? match[1] : null;
}

// Detect timeframe
function detectTimeframe(fileName: string, headers: string[]): string | null {
  const tfMatch = fileName.match(/[_\-\.](M1|M5|M15|M30|H1|H4|D1|W1|MN)[_\-\.]/i);
  return tfMatch ? tfMatch[1].toUpperCase() : null;
}

function detectGaps(rows: Record<string, string>[], dateCol: string | null): number {
  if (!dateCol || rows.length < 2) return 0;
  const timestamps = rows
    .map(r => new Date(r[dateCol]).getTime())
    .filter(t => !isNaN(t))
    .sort((a, b) => a - b);

  if (timestamps.length < 2) return 0;

  const diffs = timestamps.slice(1).map((t, i) => t - timestamps[i]);
  const minDiff = Math.min(...diffs);
  if (minDiff <= 0) return 0;

  return diffs.filter(d => d > minDiff * 1.5).length;
}

// ─── Routes ───────────────────────────────────────────────────────────────────
router.get("/", async (_req, res) => {
  const datasets = await db.select().from(datasetsTable).orderBy(datasetsTable.createdAt);
  res.json(datasets.map(d => ({
    ...d,
    isPrepared: !!d.isPrepared,
    columnStats: d.columnStats ?? null,
    previewRows: null, // omit from list
  })));
});

router.post("/", upload.single("file"), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: "No file uploaded" });

  const { asset, timeframe, name } = req.body as Record<string, string>;
  const ext = req.file.originalname.split(".").pop()?.toLowerCase() ?? "csv";
  const text = req.file.buffer.toString("utf-8");

  let parsed: { headers: string[]; rows: Record<string, string>[] };
  try {
    if (ext === "json") {
      parsed = parseJSON(text);
    } else {
      parsed = parseCSV(text);
    }
  } catch (err) {
    return res.status(400).json({ message: `Could not parse file: ${(err as Error).message}` });
  }

  const { headers, rows } = parsed;
  if (headers.length === 0) return res.status(400).json({ message: "File appears to be empty or has no columns." });

  const dateCol = detectDateColumn(headers);
  const dates = dateCol
    ? rows.map(r => r[dateCol]).filter(Boolean).sort()
    : [];

  const columnStats = computeColumnStats(headers, rows);
  const previewRows = [
    ...rows.slice(0, 10),
    ...(rows.length > 20 ? rows.slice(-5) : []),
  ];

  const [inserted] = await db.insert(datasetsTable).values({
    name: name || req.file.originalname.replace(/\.[^.]+$/, ""),
    asset: asset || detectAsset(req.file.originalname, headers),
    timeframe: timeframe || detectTimeframe(req.file.originalname, headers),
    fileName: req.file.originalname,
    fileType: ext,
    fileContent: text,
    rowCount: rows.length,
    columns: headers as unknown as string[],
    startDate: dates[0] ?? null,
    endDate: dates[dates.length - 1] ?? null,
    columnStats: columnStats as unknown as Record<string, unknown>[],
    previewRows: previewRows as unknown as Record<string, unknown>[],
    isPrepared: 0,
  }).returning();

  res.status(201).json({ ...inserted, isPrepared: !!inserted.isPrepared });
});

router.get("/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  const [ds] = await db.select().from(datasetsTable).where(eq(datasetsTable.id, id));
  if (!ds) return res.status(404).json({ message: "Dataset not found" });
  res.json({ ...ds, isPrepared: !!ds.isPrepared });
});

router.delete("/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  await db.delete(datasetsTable).where(eq(datasetsTable.id, id));
  res.status(204).send();
});

router.post("/:id/prepare", async (req, res) => {
  const id = parseInt(req.params.id);
  const [ds] = await db.select().from(datasetsTable).where(eq(datasetsTable.id, id));
  if (!ds) return res.status(404).json({ message: "Dataset not found" });

  const opts = req.body as { removeNulls?: boolean; detectGaps?: boolean; normalize?: boolean };
  const removeNulls = opts.removeNulls !== false;
  const detectGapsOpt = opts.detectGaps !== false;
  const normalize = opts.normalize === true;

  // Re-parse the raw file content
  const ext = ds.fileType;
  let parsed: { headers: string[]; rows: Record<string, string>[] };
  try {
    parsed = ext === "json" ? parseJSON(ds.fileContent) : parseCSV(ds.fileContent);
  } catch {
    return res.status(400).json({ message: "Could not re-parse file for preparation." });
  }

  let { headers, rows } = parsed;
  const report: string[] = [];

  // 1. Remove rows with nulls in OHLCV columns
  let nullsRemoved = 0;
  if (removeNulls) {
    const before = rows.length;
    const ohlcvCols = headers.filter(h =>
      /^(open|high|low|close|volume|vol|price|bid|ask)/i.test(h)
    );
    rows = rows.filter(row =>
      ohlcvCols.every(c => row[c] !== "" && row[c] != null && !isNaN(Number(row[c])))
    );
    nullsRemoved = before - rows.length;
    if (nullsRemoved > 0) report.push(`Removed ${nullsRemoved} rows with null/invalid OHLCV values.`);
    else report.push("No null/invalid OHLCV rows detected.");
  }

  // 2. Detect gaps
  let gapsDetected = 0;
  if (detectGapsOpt) {
    const dateCol = detectDateColumn(headers);
    gapsDetected = detectGaps(rows, dateCol);
    report.push(
      gapsDetected > 0
        ? `Detected ${gapsDetected} time gap(s) in the data series.`
        : "No time gaps detected in the data series."
    );
  }

  // 3. Normalize OHLCV columns to 6 decimal places
  if (normalize) {
    const numericCols = headers.filter(h => {
      const sample = rows.slice(0, 20).map(r => Number(r[h]));
      return sample.filter(n => !isNaN(n)).length > 15;
    });
    rows = rows.map(row => {
      const newRow = { ...row };
      numericCols.forEach(c => {
        const n = Number(row[c]);
        if (!isNaN(n)) newRow[c] = n.toFixed(6);
      });
      return newRow;
    });
    report.push(`Normalized ${numericCols.length} numeric column(s) to 6 decimal places.`);
  }

  // Recompute stats on cleaned data
  const columnStats = computeColumnStats(headers, rows);
  const dateCol = detectDateColumn(headers);
  const dates = dateCol ? rows.map(r => r[dateCol]).filter(Boolean).sort() : [];
  const previewRows = [...rows.slice(0, 10), ...(rows.length > 20 ? rows.slice(-5) : [])];

  const [updated] = await db
    .update(datasetsTable)
    .set({
      rowCount: rows.length,
      columnStats: columnStats as unknown as Record<string, unknown>[],
      previewRows: previewRows as unknown as Record<string, unknown>[],
      startDate: dates[0] ?? ds.startDate,
      endDate: dates[dates.length - 1] ?? ds.endDate,
      gapsDetected,
      nullsRemoved,
      isPrepared: 1,
      preparationReport: report.join(" "),
      updatedAt: new Date(),
    })
    .where(eq(datasetsTable.id, id))
    .returning();

  res.json({ ...updated, isPrepared: true });
});

export default router;
