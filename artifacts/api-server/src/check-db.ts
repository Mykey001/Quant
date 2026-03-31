import { db } from './src/lib/index.ts';
import { stepResultsTable } from '../../lib/db/src/schema/strategies.ts';
import { desc, eq } from 'drizzle-orm';

async function check() {
  try {
    const res = await db.select().from(stepResultsTable).orderBy(desc(stepResultsTable.id)).limit(20);
    console.log(JSON.stringify(res.map(r => ({ 
      step: r.stepNumber, 
      name: r.stepName, 
      status: r.status, 
      error: r.findings?.slice(0, 100) 
    })), null, 2));
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
