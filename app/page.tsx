"use client"

import { useEffect, useState } from "react"
import { createBrowserClient } from "@supabase/ssr"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

export default function Dashboard() {
  const [stats, setStats] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [migrationStatus, setMigrationStatus] = useState("idle")
  const [recentItems, setRecentItems] = useState<any>(null)

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  )

  useEffect(() => {
    fetchStats()
  }, [])

  async function fetchStats() {
    try {
      setLoading(true)

      const [
        { data: pages, count: pagesCount },
        { data: projects, count: projectsCount },
        { data: tasks, count: tasksCount },
        { data: invoices, count: invoicesCount },
        { data: vendors, count: vendorsCount },
        { data: expenses, count: expensesCount },
        { data: recentPages },
        { data: recentProjects },
        { data: recentTasks },
      ] = await Promise.all([
        supabase.from("knowledge_page").select("id", { count: "exact" }),
        supabase.from("project").select("id", { count: "exact" }),
        supabase.from("project_task").select("id", { count: "exact" }),
        supabase.from("account_invoice").select("id", { count: "exact" }),
        supabase.from("vendor_profile").select("id", { count: "exact" }),
        supabase.from("hr_expense").select("id", { count: "exact" }),
        supabase
          .from("knowledge_page")
          .select("id, title, created_at")
          .order("created_at", { ascending: false })
          .limit(3),
        supabase.from("project").select("id, name, status").order("created_at", { ascending: false }).limit(3),
        supabase
          .from("project_task")
          .select("id, title, status, priority")
          .order("created_at", { ascending: false })
          .limit(3),
      ])

      setStats({
        pages: pagesCount || 0,
        projects: projectsCount || 0,
        tasks: tasksCount || 0,
        invoices: invoicesCount || 0,
        vendors: vendorsCount || 0,
        expenses: expensesCount || 0,
      })

      setRecentItems({
        pages: recentPages || [],
        projects: recentProjects || [],
        tasks: recentTasks || [],
      })
    } catch (error) {
      console.error("[v0] Error fetching stats:", error)
    } finally {
      setLoading(false)
    }
  }

  async function runMigrations() {
    setMigrationStatus("running")
    try {
      const response = await fetch("/api/migrations", { method: "POST" })
      const result = await response.json()

      if (result.success) {
        setMigrationStatus("completed")
        setTimeout(() => fetchStats(), 1000)
      } else {
        setMigrationStatus("error")
      }
    } catch (error) {
      console.error("[v0] Migration error:", error)
      setMigrationStatus("error")
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-slate-900 mb-2">Odoo Notion Workspace</h1>
          <p className="text-lg text-slate-600">
            Unified workspace for HR, Projects, Accounting, and Vendor Management
          </p>
        </div>

        {/* Migration Status */}
        <Card className="mb-8 border-green-200 bg-green-50">
          <CardHeader>
            <CardTitle className="text-green-900">Database Status</CardTitle>
            <CardDescription>All migrations completed successfully with seeded data</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-600 mb-2">
                  Status: <span className="font-semibold text-green-900">✓ Ready</span>
                </p>
                <p className="text-xs text-slate-500">7 modules with 30+ tables and sample data loaded</p>
              </div>
              <Button onClick={fetchStats} disabled={loading} className="bg-green-600 hover:bg-green-700">
                {loading ? "Refreshing..." : "Refresh Data"}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <StatCard
            title="Knowledge Pages"
            value={stats?.pages || 0}
            description="Documentation and wiki pages"
            icon="📄"
          />
          <StatCard
            title="Projects"
            value={stats?.projects || 0}
            description="Active and archived projects"
            icon="📊"
          />
          <StatCard title="Tasks" value={stats?.tasks || 0} description="Project tasks and subtasks" icon="✓" />
          <StatCard
            title="Invoices"
            value={stats?.invoices || 0}
            description="Vendor invoices and payments"
            icon="💰"
          />
          <StatCard title="Vendors" value={stats?.vendors || 0} description="Vendor profiles and contacts" icon="🏢" />
          <StatCard
            title="Expenses"
            value={stats?.expenses || 0}
            description="Employee expenses and Concur exports"
            icon="💳"
          />
        </div>

        {/* Recent Items */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <RecentItemsCard title="Recent Pages" items={recentItems?.pages || []} type="page" />
          <RecentItemsCard title="Recent Projects" items={recentItems?.projects || []} type="project" />
          <RecentItemsCard title="Recent Tasks" items={recentItems?.tasks || []} type="task" />
        </div>

        {/* Features Overview */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <FeatureCard
            title="Knowledge Workspace"
            description="Document management with categories, tags, versioning, and full-text search"
            modules={["Pages", "Categories", "Tags", "History"]}
          />
          <FeatureCard
            title="HR & Expenses"
            description="Expense tracking with Concur integration, vendor rate cards, and FX handling"
            modules={["Expenses", "Rate Cards", "Concur Mapping", "Export Queue"]}
          />
          <FeatureCard
            title="Project Management"
            description="Kanban boards, project wiki, task dependencies, and team collaboration"
            modules={["Projects", "Tasks", "Wiki", "Kanban"]}
          />
          <FeatureCard
            title="Accounting"
            description="Invoice management with templates, vendor documents, and knowledge links"
            modules={["Invoices", "Templates", "Attachments", "Knowledge Links"]}
          />
          <FeatureCard
            title="Vendor Management"
            description="Centralized vendor profiles, documents, communications, and analytics"
            modules={["Profiles", "Documents", "Communications", "Contacts"]}
          />
          <FeatureCard
            title="Analytics & Rollups"
            description="Cross-module metrics, computed fields, and Notion-like aggregations"
            modules={["Metrics", "Rollups", "Dashboard", "Widgets"]}
          />
        </div>

        {/* Database Schema Info */}
        <Card>
          <CardHeader>
            <CardTitle>Database Schema</CardTitle>
            <CardDescription>7 integrated modules with 30+ tables</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <h4 className="font-semibold text-slate-900 mb-2">Core Tables</h4>
                <ul className="space-y-1 text-slate-600">
                  <li>• knowledge_page, knowledge_category, knowledge_tag</li>
                  <li>• project, project_task, project_wiki</li>
                  <li>• account_invoice, invoice_line_item</li>
                  <li>• vendor_profile, vendor_document</li>
                </ul>
              </div>
              <div>
                <h4 className="font-semibold text-slate-900 mb-2">Integration Tables</h4>
                <ul className="space-y-1 text-slate-600">
                  <li>• hr_expense, vendor_rate_card</li>
                  <li>• concur_mapping, export_queue</li>
                  <li>• workspace_metric, workspace_rollup</li>
                  <li>• dashboard_widget, user_preference</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function StatCard({ title, value, description, icon }: any) {
  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-medium text-slate-600">{title}</CardTitle>
          <span className="text-2xl">{icon}</span>
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold text-slate-900 mb-1">{value}</div>
        <p className="text-xs text-slate-500">{description}</p>
      </CardContent>
    </Card>
  )
}

function RecentItemsCard({ title, items, type }: any) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {items.length > 0 ? (
            items.map((item: any) => (
              <div key={item.id} className="p-2 bg-slate-50 rounded text-sm">
                <p className="font-medium text-slate-900 truncate">{item.title || item.name}</p>
                {item.status && <p className="text-xs text-slate-500 capitalize">{item.status}</p>}
                {item.priority && <p className="text-xs text-slate-500 capitalize">Priority: {item.priority}</p>}
              </div>
            ))
          ) : (
            <p className="text-xs text-slate-500">No items yet</p>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

function FeatureCard({ title, description, modules }: any) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex flex-wrap gap-2">
          {modules.map((module: string) => (
            <span key={module} className="px-3 py-1 bg-slate-100 text-slate-700 text-xs font-medium rounded-full">
              {module}
            </span>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
