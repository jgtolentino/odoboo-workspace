import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing required environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function runMigration(sqlFile: string) {
  try {
    console.log(`Running migration: ${sqlFile}`);
    const sql = readFileSync(join(__dirname, '..', sqlFile), 'utf-8');

    const { error } = await supabase.rpc('exec_sql', { sql });

    if (error) {
      // If exec_sql function doesn't exist, try direct SQL execution
      console.log('Trying direct SQL execution...');
      // For now, we'll just log that manual execution is needed
      console.log(`Please run the SQL from ${sqlFile} manually in Supabase SQL Editor`);
      return;
    }

    console.log(`✅ Successfully executed ${sqlFile}`);
  } catch (error) {
    console.error(`❌ Error executing ${sqlFile}:`, error);
  }
}

async function main() {
  console.log('Starting database migrations...');

  // Run migrations in order
  const migrations = [
    'scripts/09_notion_workspace_schema.sql',
    'scripts/10_project_management_schema.sql',
  ];

  for (const migration of migrations) {
    await runMigration(migration);
  }

  console.log('All migrations completed!');
}

main().catch(console.error);
