# Workspace

## Overview

pnpm workspace monorepo using TypeScript. Each package manages its own dependencies.

## Stack

- **Monorepo tool**: pnpm workspaces
- **Node.js version**: 24
- **Package manager**: pnpm
- **TypeScript version**: 5.9
- **API framework**: Express 5
- **Database**: PostgreSQL + Drizzle ORM
- **Validation**: Zod (`zod/v4`), `drizzle-zod`
- **API codegen**: Orval (from OpenAPI spec)
- **Build**: esbuild (CJS bundle)
- **AI**: OpenAI via Replit AI Integrations (`gpt-5-mini`)
- **File upload**: multer (supports MQ5, PineScript, Python, MQL4, etc.)

## Structure

```text
artifacts-monorepo/
├── artifacts/              # Deployable applications
│   ├── api-server/         # Express API server
│   └── quant-research/     # React + Vite frontend (trading research platform)
├── lib/                    # Shared libraries
│   ├── api-spec/           # OpenAPI spec + Orval codegen config
│   ├── api-client-react/   # Generated React Query hooks
│   ├── api-zod/            # Generated Zod schemas from OpenAPI
│   ├── db/                 # Drizzle ORM schema + DB connection
│   └── integrations-openai-ai-server/  # OpenAI AI integration client
├── scripts/                # Utility scripts
├── pnpm-workspace.yaml     # pnpm workspace
├── tsconfig.base.json      # Shared TS options
├── tsconfig.json           # Root TS project references
└── package.json            # Root package with hoisted devDeps
```

## Features

### Quant Research Platform (`artifacts/quant-research`)

A full-stack quantitative trading research platform with:

1. **File Upload** - Drag and drop or browse to upload trading strategy files (.mq5, .mql4, .pine, .py, .txt and more)
2. **10-Step AI Analysis Pipeline** - Automated pipeline powered by GPT:
   - Step 1: Strategy Deconstruction
   - Step 2: Data Collection & Preparation
   - Step 3: Baseline Backtest
   - Step 4: Market Regime Segmentation
   - Step 5: Model Training & Adaptation
   - Step 6: Parameter Optimization
   - Step 7: Validation (Out-of-Sample)
   - Step 8: Walk-Forward Analysis
   - Step 9: Risk & Failure Analysis
   - Step 10: Final Output & Recommendations
3. **Live Progress Tracking** - Real-time step-by-step progress as each agent runs
4. **Metrics & Charts** - Sharpe ratio, Sortino ratio, max drawdown, win rate, profit factor, and more
5. **Dark trading terminal UI** with sidebar navigation

## Database Schema

- `strategies` - Uploaded trading strategy files
- `analysis_runs` - Analysis pipeline runs per strategy
- `step_results` - Individual step results for each run (10 steps per run)

## TypeScript & Composite Projects

Every package extends `tsconfig.base.json` which sets `composite: true`. The root `tsconfig.json` lists all packages as project references.

## Root Scripts

- `pnpm run build` — runs `typecheck` first, then recursively runs `build` in all packages that define it
- `pnpm run typecheck` — runs `tsc --build --emitDeclarationOnly` using project references

## Packages

### `artifacts/api-server` (`@workspace/api-server`)

Express 5 API server. Routes:
- `GET /api/strategies` — list all strategies
- `POST /api/strategies` — upload strategy file (multipart/form-data)
- `GET /api/strategies/:id` — get strategy details
- `DELETE /api/strategies/:id` — delete strategy
- `POST /api/strategies/:id/analyze` — start 10-step analysis pipeline
- `GET /api/runs` — list all analysis runs
- `GET /api/runs/:id` — get run details
- `GET /api/runs/:id/steps` — get step results for a run

### `artifacts/quant-research` (`@workspace/quant-research`)

React + Vite frontend with dark trading terminal theme.
- Dashboard, Strategies list/detail, Analysis Runs list/detail pages
- Recharts for metrics visualization
- React Dropzone for file upload
- Framer Motion for animations

### `lib/db` (`@workspace/db`)

Database layer using Drizzle ORM with PostgreSQL.

### `lib/api-spec` (`@workspace/api-spec`)

OpenAPI 3.1 spec + Orval codegen config.
Run codegen: `pnpm --filter @workspace/api-spec run codegen`

### `lib/integrations-openai-ai-server` (`@workspace/integrations-openai-ai-server`)

OpenAI client via Replit AI Integrations. Uses env vars `AI_INTEGRATIONS_OPENAI_BASE_URL` and `AI_INTEGRATIONS_OPENAI_API_KEY`.
