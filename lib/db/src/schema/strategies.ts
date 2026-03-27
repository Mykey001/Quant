import { pgTable, serial, text, timestamp, integer, jsonb } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const strategiesTable = pgTable("strategies", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description").default(""),
  fileType: text("file_type").notNull(),
  fileName: text("file_name").notNull(),
  fileContent: text("file_content").notNull(),
  strategyType: text("strategy_type"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const insertStrategySchema = createInsertSchema(strategiesTable).omit({ id: true, createdAt: true, updatedAt: true });
export type InsertStrategy = z.infer<typeof insertStrategySchema>;
export type Strategy = typeof strategiesTable.$inferSelect;

export const analysisRunsTable = pgTable("analysis_runs", {
  id: serial("id").primaryKey(),
  strategyId: integer("strategy_id").notNull().references(() => strategiesTable.id, { onDelete: "cascade" }),
  status: text("status").notNull().default("pending"),
  currentStep: integer("current_step"),
  totalSteps: integer("total_steps").notNull().default(10),
  options: jsonb("options").notNull().default({}),
  summary: text("summary"),
  errorMessage: text("error_message"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const insertAnalysisRunSchema = createInsertSchema(analysisRunsTable).omit({ id: true, createdAt: true, updatedAt: true });
export type InsertAnalysisRun = z.infer<typeof insertAnalysisRunSchema>;
export type AnalysisRun = typeof analysisRunsTable.$inferSelect;

export const stepResultsTable = pgTable("step_results", {
  id: serial("id").primaryKey(),
  runId: integer("run_id").notNull().references(() => analysisRunsTable.id, { onDelete: "cascade" }),
  stepNumber: integer("step_number").notNull(),
  stepName: text("step_name").notNull(),
  status: text("status").notNull().default("pending"),
  findings: text("findings"),
  metrics: jsonb("metrics"),
  recommendations: text("recommendations"),
  startedAt: timestamp("started_at"),
  completedAt: timestamp("completed_at"),
});

export const insertStepResultSchema = createInsertSchema(stepResultsTable).omit({ id: true });
export type InsertStepResult = z.infer<typeof insertStepResultSchema>;
export type StepResult = typeof stepResultsTable.$inferSelect;
