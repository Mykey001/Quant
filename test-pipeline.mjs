import fs from 'fs';
import path from 'path';

const API_URL = 'http://127.0.0.1:5000/api';
const STRATEGY_PATH = path.resolve('v4 - goldmine_combined.mq5');
const DATASET_PATH = path.resolve('XAUUSD_M1.csv');

async function run() {
  console.log('--- QUANT RESEARCH PIPELINE START ---');

  // 1. Upload Strategy
  console.log('1. Uploading strategy file...', STRATEGY_PATH);
  if (!fs.existsSync(STRATEGY_PATH)) {
    console.error('MQ5 file not found!');
    return;
  }
  const strategyFileBlob = new Blob([fs.readFileSync(STRATEGY_PATH)], { type: 'text/plain' });
  const strategyFormData = new FormData();
  strategyFormData.append('file', strategyFileBlob, 'v4 - goldmine_combined.mq5');
  const strategyUploadRes = await fetch(`${API_URL}/strategies`, {
    method: 'POST',
    body: strategyFormData,
  });
  if (!strategyUploadRes.ok) {
    console.error('Strategy upload failed', await strategyUploadRes.text());
    return;
  }
  const strategy = await strategyUploadRes.json();
  const strategyId = strategy.id;
  console.log(`✅ Strategy Uploaded! ID: ${strategyId}`);

  // 2. Upload Dataset
  console.log('2. Uploading dataset file...', DATASET_PATH);
  if (!fs.existsSync(DATASET_PATH)) {
    console.error('CSV file not found!');
    return;
  }
  const datasetFileBlob = new Blob([fs.readFileSync(DATASET_PATH)], { type: 'text/csv' });
  const datasetFormData = new FormData();
  datasetFormData.append('file', datasetFileBlob, 'XAUUSD_M1.csv');
  const datasetUploadRes = await fetch(`${API_URL}/datasets`, {
    method: 'POST',
    body: datasetFormData,
  });
  if (!datasetUploadRes.ok) {
    console.error('Dataset upload failed', await datasetUploadRes.text());
    return;
  }
  const dataset = await datasetUploadRes.json();
  const datasetId = dataset.id;
  console.log(`✅ Dataset Uploaded! ID: ${datasetId}`);

  // 3. Prepare Dataset
  console.log(`3. Preparing dataset ${datasetId}...`);
  const prepareRes = await fetch(`${API_URL}/datasets/${datasetId}/prepare`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ normalize: true, detectGaps: true })
  });
  if (!prepareRes.ok) {
    console.error('Dataset preparation failed', await prepareRes.text());
    return;
  }
  const preparedData = await prepareRes.json();
  console.log(`✅ Dataset Prepared! Report: ${preparedData.preparationReport}`);

  // 4. Start Analysis Pipeline
  console.log('4. Starting 10-Step Analysis Pipeline...');
  const analyzeRes = await fetch(`${API_URL}/strategies/${strategyId}/analyze`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      markets: ['XAUUSD'], 
      timeframes: ['M1'],
      datasetId: datasetId // Though the backend might not use it yet, we pass it for completeness
    })
  });
  if (!analyzeRes.ok) {
    console.error('Analyze trigger failed', await analyzeRes.text());
    return;
  }
  const runData = await analyzeRes.json();
  const runId = runData.id;
  console.log(`✅ Pipeline Started! Run ID: ${runId}`);

  // 5. Poll for Results
  console.log('5. Polling for results... (This takes time as GPT runs 10 steps)');
  let isDone = false;
  let currentStepPrinted = 0;

  while (!isDone) {
    const runRes = await fetch(`${API_URL}/runs/${runId}`);
    const runInfo = await runRes.json();

    const stepsRes = await fetch(`${API_URL}/runs/${runId}/steps`);
    const steps = await stepsRes.json();

    for (const step of steps) {
      if (step.status === 'completed' && step.stepNumber > currentStepPrinted) {
        console.log(`\n🎉 Step ${step.stepNumber} [${step.stepName}] Completed!`);
        console.log(`Findings: ${step.findings}...`);
        console.log(`Metrics:`, JSON.stringify(step.metrics));
        currentStepPrinted = step.stepNumber;
      } else if (step.status === 'failed') {
        console.error(`\n❌ Step ${step.stepNumber} [${step.stepName}] FAILED!`);
        console.error(step.findings);
        isDone = true;
      }
    }

    if (runInfo.status === 'completed') {
      console.log(`\n🚀 FULL PIPELINE FINISHED SUCCESSFULLY!`);
      isDone = true;
    } else if (runInfo.status === 'failed') {
      console.log(`\n💥 PIPELINE FAILED! Error: ${runInfo.errorMessage}`);
      isDone = true;
    } else {
      process.stdout.write('.');
      await new Promise(r => setTimeout(r, 5000));
    }
  }
}

run().catch(console.error);
