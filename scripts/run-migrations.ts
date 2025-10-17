import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(supabaseUrl, supabaseKey)

const migrationFiles = [
  "01_knowledge_workspace_schema.sql",
  "02_hr_expense_schema.sql",
  "03_project_workspace_schema.sql",
  "04_invoice_knowledge_schema.sql",
  "05_vendor_knowledge_schema.sql",
  "06_workspace_analytics_schema.sql",
  "07_workspace_dashboard_schema.sql",
  "08_seed_data.sql",
]

async function runMigrations() {
  console.log("[v0] Starting database migrations...")

  for (const file of migrationFiles) {
    try {
      console.log(`[v0] Running migration: ${file}`)

      // Read SQL file content
      const response = await fetch(`/scripts/${file}`)
      const sql = await response.text()

      // Execute migration
      const { error } = await supabase.rpc("exec_sql", { sql })

      if (error) {
        console.error(`[v0] Error in ${file}:`, error)
      } else {
        console.log(`[v0] ✓ Completed: ${file}`)
      }
    } catch (err) {
      console.error(`[v0] Failed to run ${file}:`, err)
    }
  }

  console.log("[v0] All migrations completed!")
}

runMigrations()
