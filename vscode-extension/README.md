# Odoo Workspace (Supabase-Ops)

VS Code extension for Odoo development with integrated deployment monitoring across Vercel, Supabase, GitHub Actions, and DigitalOcean.

## Features

### Odoo Development Tools
- **Launch Dev Server**: Start Odoo with configured addons path
- **RPC Console**: Interactive JSON-RPC console for model operations
- **Schema Guard**: Detect schema drift, duplicate tables, and RLS violations

### Quality Assurance
- **Visual Snapshot**: Playwright-based screenshot capture with SSIM comparison
- **Custom Visual API Integration**: Advanced visual regression with PaddleOCR-VL + CLIP + LPIPS
- **Test Impact Analysis**: Run only tests affected by code changes

### Deployment Monitoring
Real-time deployment status across all platforms in VS Code sidebar:
- **Vercel**: Production deployment status, URLs, deploy time
- **Supabase**: Database health, Edge Functions, migration status
- **GitHub Actions**: Workflow runs, CI/CD status
- **DigitalOcean**: App Platform deployment phase and health

## Installation

### From Source
```bash
cd vscode-extension
npm install
npm run compile
npm run package
```

Install the generated `.vsix` file:
```bash
code --install-extension odoo-workspace-supabase-ops-0.1.0.vsix
```

### Prerequisites
- Node.js 18+ and npm
- Python 3.8+ (for Odoo)
- Playwright browsers: `npx playwright install --with-deps chromium`

## Configuration

### VS Code Settings
Open Settings (Cmd+,) and configure:

#### Odoo Settings
```json
{
  "odoo.pythonPath": "python",
  "odoo.bin": "odoo",
  "odoo.addonsPath": "addons",
  "odoo.config": "odoo.conf"
}
```

#### Database Settings
```json
{
  "supabase.projectRef": "xkxyvboeubffxxbebsll",
  "supabase.url": "https://xkxyvboeubffxxbebsll.supabase.co",
  "supabase.serviceRoleKey": "${env:SUPABASE_SERVICE_ROLE_KEY}",
  "supabase.connectionString": "${env:POSTGRES_URL}"
}
```

#### Deployment Monitoring
```json
{
  "vercel.token": "${env:VERCEL_TOKEN}",
  "vercel.projectId": "prj_...",
  "vercel.teamId": "team_...",

  "github.token": "${env:GITHUB_TOKEN}",
  "github.repo": "owner/repo",

  "digitalocean.token": "${env:DO_ACCESS_TOKEN}",
  "digitalocean.appId": "b1bb1b07-46a6-4bbb-85a2-e1e8c7f263b9"
}
```

#### QA Settings
```json
{
  "qa.baseUrl": "http://localhost:8069",
  "qa.visualApiUrl": "http://localhost:8080"
}
```

### Environment Variables
Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Supabase
export SUPABASE_PROJECT_REF=xkxyvboeubffxxbebsll
export SUPABASE_URL=https://xkxyvboeubffxxbebsll.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
export POSTGRES_URL=postgresql://postgres...

# Vercel
export VERCEL_TOKEN=your_vercel_token

# GitHub
export GITHUB_TOKEN=github_pat_...

# DigitalOcean
export DO_ACCESS_TOKEN=dop_v1_...
```

## Usage

### Command Palette
Press `Cmd+Shift+P` and search:

- `Odoo: Launch Dev Server` - Start Odoo development server
- `Odoo: Open RPC Console` - Interactive JSON-RPC console
- `DB: Run Schema Guard` - Schema drift detection
- `QA: Visual Snapshot` - Capture and compare screenshots
- `Tests: Run Impacted` - Run tests for changed code only
- `Platform: Check Deployment Status` - Refresh deployment status

### Deployment Status View
1. Open the **Odoo Workspace** sidebar icon
2. View real-time status for all platforms
3. Click URLs to open in browser
4. Auto-refreshes every 30 seconds

### RPC Console
```javascript
// Authenticate with Odoo
// Enter database, username, password

// Example: Search partners
{
  "model": "res.partner",
  "method": "search_read",
  "args": [[["is_company", "=", true]]],
  "kwargs": {"fields": ["name", "email"], "limit": 5}
}

// Example: Create record
{
  "model": "res.partner",
  "method": "create",
  "args": [{"name": "Test Company", "is_company": true}],
  "kwargs": {}
}
```

### Visual Snapshot Workflow
1. Run `QA: Visual Snapshot`
2. Enter page path (e.g., `/web/login`)
3. First run creates baseline
4. Subsequent runs compare with SSIM
5. If `qa.visualApiUrl` configured, uses advanced comparison:
   - SSIM (structural similarity)
   - LPIPS (perceptual similarity)
   - CLIP (semantic similarity)
   - JSON diff for structured data extraction

### Schema Guard
Detects and reports:
- **Duplicate tables**: `users` vs `users_v2` vs `users_backup`
- **Column drift**: Different column types/nullability for same column name
- **RLS violations**: Tables in `gold`/`platinum` without Row Level Security policies
- **Naming inconsistencies**: Mixed `snake_case` and `camelCase`

## Development

### Build
```bash
npm run compile
```

### Watch Mode
```bash
npm run watch
```

### Lint
```bash
npm run lint
```

### Package
```bash
npm run package
```

## Architecture

### Providers
- **VercelProvider**: Fetches deployment status from Vercel API
- **SupabaseProvider**: Checks project health via Supabase client
- **GitHubProvider**: Queries GitHub Actions workflow runs via Octokit
- **DigitalOceanProvider**: Monitors App Platform deployments
- **DeploymentStatusProvider**: Aggregates all providers into TreeView

### Commands
- **launchOdoo.ts**: Terminal-based Odoo server launcher
- **rpcConsole.ts**: WebView-based JSON-RPC interactive console
- **schemaGuard.ts**: PostgreSQL schema drift detection
- **visualSnapshot.ts**: Playwright screenshot + SSIM comparison
- **testImpact.ts**: Jest/Pytest changed test execution
- **deploymentStatus.ts**: Deployment status refresh trigger

## Troubleshooting

### "Not configured" status
- Check environment variables are exported
- Verify VS Code settings reference `${env:...}`
- Reload VS Code window

### Visual snapshot fails
- Ensure Playwright browsers installed: `npx playwright install chromium`
- Check `qa.baseUrl` is reachable
- Verify `.snapshots/` directory exists

### RPC console authentication fails
- Verify Odoo server is running
- Check database name, username, password
- Ensure `odoo.config` points to correct config file

### Schema Guard no results
- Check `supabase.connectionString` is valid
- Verify PostgreSQL connection allows direct access
- Ensure schemas (`bronze`, `silver`, `gold`, `platinum`) exist

## License

MIT

## Support

For issues, questions, or contributions, please open an issue on GitHub.
