import * as vscode from 'vscode';
import { Client } from 'pg';

const DUPLICATE_TABLES_SQL = `
WITH t AS (
  SELECT table_schema, table_name,
         regexp_replace(table_name, '(s$|_v[0-9]+$|_backup$|_tmp$|_copy$)', '', 'gi') AS stem
  FROM information_schema.tables
  WHERE table_schema NOT IN ('pg_catalog', 'information_schema') AND table_type = 'BASE TABLE'
)
SELECT stem,
       json_agg(json_build_object('schema', table_schema, 'table', table_name) ORDER BY table_schema, table_name) AS candidates
FROM t
GROUP BY stem
HAVING count(*) > 1
ORDER BY stem;
`;

const COLUMN_DRIFT_SQL = `
WITH cols AS (
  SELECT c.table_schema, c.table_name,
         regexp_replace(c.table_name, '(s$|_v[0-9]+$|_backup$|_tmp$|_copy$)', '', 'gi') AS stem,
         c.column_name, c.data_type
  FROM information_schema.columns c
  WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
)
SELECT stem, column_name,
       json_agg(DISTINCT data_type) AS types,
       json_agg(DISTINCT table_schema || '.' || table_name) AS tables
FROM cols
GROUP BY stem, column_name
HAVING count(DISTINCT table_schema || '.' || table_name) > 1
ORDER BY stem, column_name;
`;

const RLS_VIOLATIONS_SQL = `
SELECT n.nspname AS schema, c.relname AS table,
       NOT EXISTS(SELECT 1 FROM pg_policies p WHERE p.schemaname = n.nspname AND p.tablename = c.relname) AS missing_policy
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('gold', 'platinum', 'public')
  AND c.relkind = 'r'
  AND c.relrowsecurity = true
HAVING NOT EXISTS(SELECT 1 FROM pg_policies p WHERE p.schemaname = n.nspname AND p.tablename = c.relname);
`;

export async function runSchemaGuard() {
  const config = vscode.workspace.getConfiguration();
  const connectionString = config.get<string>('supabase.connectionString');

  if (!connectionString) {
    vscode.window.showErrorMessage(
      'Supabase connection string not configured. Set "supabase.connectionString" in settings.'
    );
    return;
  }

  const client = new Client({ connectionString });

  try {
    await client.connect();
    vscode.window.showInformationMessage('Running schema guard checks...');

    // Run all checks in parallel
    const [duplicates, drift, rlsViolations] = await Promise.all([
      client.query(DUPLICATE_TABLES_SQL),
      client.query(COLUMN_DRIFT_SQL),
      client.query(RLS_VIOLATIONS_SQL),
    ]);

    // Format results
    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        duplicateTables: duplicates.rows.length,
        columnDrift: drift.rows.length,
        rlsViolations: rlsViolations.rows.length,
      },
      duplicateTables: duplicates.rows,
      columnDrift: drift.rows,
      rlsViolations: rlsViolations.rows,
    };

    // Show results in new document
    const doc = await vscode.workspace.openTextDocument({
      language: 'json',
      content: JSON.stringify(report, null, 2),
    });

    await vscode.window.showTextDocument(doc, { preview: false });

    // Show summary
    const totalIssues = report.summary.duplicateTables + report.summary.columnDrift + report.summary.rlsViolations;
    if (totalIssues === 0) {
      vscode.window.showInformationMessage('✅ Schema Guard: No issues found!');
    } else {
      vscode.window.showWarningMessage(
        `⚠️ Schema Guard: Found ${totalIssues} issues (${report.summary.duplicateTables} duplicates, ${report.summary.columnDrift} drift, ${report.summary.rlsViolations} RLS violations)`
      );
    }
  } catch (error) {
    vscode.window.showErrorMessage(`Schema Guard error: ${error}`);
  } finally {
    await client.end();
  }
}
