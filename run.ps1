$env:DATABASE_URL="postgresql://neondb_owner:npg_g9kat3WZbVxB@ep-plain-resonance-amdl4hrc-pooler.c-5.us-east-1.aws.neon.tech/Quant?sslmode=require&channel_binding=require"
$env:GEMINI_API_KEY="AIzaSyAwunVJYhwjpl3Th_p9VdMrbZ0LJHNiN38"

Write-Host "Installing dependencies..."
npx --yes pnpm install

Write-Host "Pushing DB schema..."
npx --yes pnpm --filter @workspace/db run push

Write-Host "Building project..."
npx --yes pnpm run build

Write-Host "Starting API server (port 5000)..."
Start-Process powershell -ArgumentList "-NoExit -Command `"cd artifacts/api-server; `$env:PORT=5000; `$env:DATABASE_URL='$env:DATABASE_URL'; `$env:GEMINI_API_KEY='$env:GEMINI_API_KEY'; npx pnpm run dev`""

Write-Host "Starting Frontend (port 5173)..."
Start-Process powershell -ArgumentList "-NoExit -Command `"cd artifacts/quant-research; `$env:PORT=5173; `$env:BASE_PATH='/'; `$env:VITE_API_URL='http://localhost:5000'; npx --yes pnpm run dev`""

Write-Host "Servers started. Please check the new PowerShell windows for logs."
