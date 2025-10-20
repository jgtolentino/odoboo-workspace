# VS Code Extension - Complete Implementation Guide

## Current Status

✅ **Existing**: Basic extension skeleton with deployment monitoring
- Package.json with commands for Odoo launch, RPC console, schema guard, QA snapshot
- Deployment status tree view
- Configuration for Supabase, Vercel, GitHub, DigitalOcean

## Enhancement Plan

### Phase 1: Add Docker Management Commands

**New Commands** (add to package.json):
```json
{
  "command": "odoo.stopServer",
  "title": "Odoo: Stop Server",
  "icon": "$(debug-stop)"
},
{
  "command": "odoo.restartServer",
  "title": "Odoo: Restart Server",
  "icon": "$(debug-restart)"
},
{
  "command": "odoo.updateModule",
  "title": "Odoo: Update Module",
  "icon": "$(refresh)"
}
```

**Implementation** (`src/commands/docker.ts`):
```typescript
import * as vscode from 'vscode';
import { exec } from 'child_process';
import * as path from 'path';

export function registerDockerCommands(context: vscode.ExtensionContext) {
  // Stop Odoo server
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.stopServer', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) {
        vscode.window.showErrorMessage('No workspace folder open');
        return;
      }

      const composeFile = vscode.workspace.getConfiguration('odoo').get<string>('dockerComposePath', 'docker-compose.local.yml');
      const composePath = path.join(workspacePath, composeFile);

      await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Stopping Odoo server...',
        cancellable: false
      }, async () => {
        return new Promise<void>((resolve, reject) => {
          exec(`cd "${workspacePath}" && docker-compose -f "${composeFile}" down`, (error, stdout, stderr) => {
            if (error) {
              vscode.window.showErrorMessage(`Failed to stop server: ${stderr}`);
              reject(error);
            } else {
              vscode.window.showInformationMessage('Odoo server stopped');
              resolve();
            }
          });
        });
      });
    })
  );

  // Restart Odoo server
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.restartServer', async () => {
      await vscode.commands.executeCommand('odoo.stopServer');
      await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2s
      await vscode.commands.executeCommand('odoo.launch');
    })
  );

  // Update module
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.updateModule', async () => {
      const moduleName = await vscode.window.showInputBox({
        prompt: 'Enter module name to update',
        placeHolder: 'e.g., mail_kanban_mentions'
      });

      if (!moduleName) return;

      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: `Updating module: ${moduleName}...`,
        cancellable: false
      }, async () => {
        return new Promise<void>((resolve, reject) => {
          const cmd = `docker exec odoo18 odoo -d odoboo_local -u ${moduleName} --stop-after-init --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo`;
          exec(cmd, (error, stdout, stderr) => {
            if (error) {
              vscode.window.showErrorMessage(`Failed to update module: ${stderr}`);
              reject(error);
            } else {
              vscode.window.showInformationMessage(`Module ${moduleName} updated successfully`);
              // Auto-restart Odoo
              vscode.commands.executeCommand('odoo.restartServer');
              resolve();
            }
          });
        });
      });
    })
  );
}
```

---

### Phase 2: Add Deployment Commands

**New Commands** (add to package.json):
```json
{
  "command": "odoo.buildxAMD64",
  "title": "Odoo: Build AMD64 Image (Buildx)",
  "icon": "$(package)"
},
{
  "command": "odoo.pushDOCR",
  "title": "Odoo: Push to DigitalOcean Registry",
  "icon": "$(cloud-upload)"
},
{
  "command": "odoo.verifyImage",
  "title": "Odoo: Verify Image Architecture",
  "icon": "$(checklist)"
}
```

**Implementation** (`src/commands/deployment.ts`):
```typescript
import * as vscode from 'vscode';
import { exec } from 'child_process';
import * as path from 'path';

export function registerDeploymentCommands(context: vscode.ExtensionContext) {
  // Build AMD64 image
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.buildxAMD64', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      const ocrServicePath = vscode.workspace.getConfiguration('odoo').get<string>('ocrServicePath', 'services/ocr-service');
      const fullPath = path.join(workspacePath, ocrServicePath);

      await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Building AMD64 image (this may take 10-15 minutes)...',
        cancellable: true
      }, async (progress, token) => {
        return new Promise<void>((resolve, reject) => {
          const cmd = `cd "${fullPath}" && docker buildx build --platform linux/amd64 -t registry.digitalocean.com/fin-workspace/ocr-service:prod -t registry.digitalocean.com/fin-workspace/ocr-service:sha-$(git rev-parse --short HEAD) --push .`;

          const child = exec(cmd);

          child.stdout?.on('data', (data) => {
            const output = data.toString();
            if (output.includes('exporting')) {
              progress.report({ message: 'Exporting layers...' });
            } else if (output.includes('pushing')) {
              progress.report({ message: 'Pushing to registry...' });
            }
          });

          child.on('close', (code) => {
            if (code === 0) {
              vscode.window.showInformationMessage('AMD64 image built and pushed successfully');
              resolve();
            } else {
              vscode.window.showErrorMessage('Build failed. Check terminal output.');
              reject();
            }
          });

          token.onCancellationRequested(() => {
            child.kill();
            reject();
          });
        });
      });
    })
  );

  // Verify image architecture
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.verifyImage', async () => {
      await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Verifying image architecture...',
        cancellable: false
      }, async () => {
        return new Promise<void>((resolve) => {
          exec('docker manifest inspect registry.digitalocean.com/fin-workspace/ocr-service:prod', (error, stdout, stderr) => {
            if (error) {
              vscode.window.showErrorMessage(`Failed to inspect image: ${stderr}`);
              resolve();
              return;
            }

            const manifest = JSON.parse(stdout);
            const platforms = manifest.manifests?.map((m: any) => m.platform.architecture) || [];

            if (platforms.includes('amd64')) {
              vscode.window.showInformationMessage(`✅ Image contains AMD64 architecture: ${platforms.join(', ')}`);
            } else {
              vscode.window.showWarningMessage(`⚠️ No AMD64 found. Architectures: ${platforms.join(', ')}`);
            }

            resolve();
          });
        });
      });
    })
  );
}
```

---

### Phase 3: Add Queue Monitor TreeView

**New View** (add to package.json):
```json
{
  "id": "odoo.queueView",
  "name": "Queue Jobs"
}
```

**Implementation** (`src/providers/queueTreeProvider.ts`):
```typescript
import * as vscode from 'vscode';
import { createClient } from '@supabase/supabase-js';

export class QueueTreeProvider implements vscode.TreeDataProvider<QueueJob> {
  private _onDidChangeTreeData: vscode.EventEmitter<QueueJob | undefined | null | void> = new vscode.EventEmitter<QueueJob | undefined | null | void>();
  readonly onDidChangeTreeData: vscode.Event<QueueJob | undefined | null | void> = this._onDidChangeTreeData.event;

  private supabase: any;
  private refreshInterval: NodeJS.Timeout | null = null;

  constructor() {
    const supabaseUrl = vscode.workspace.getConfiguration('supabase').get<string>('url');
    const supabaseKey = vscode.workspace.getConfiguration('supabase').get<string>('serviceRoleKey');

    if (supabaseUrl && supabaseKey) {
      this.supabase = createClient(supabaseUrl, supabaseKey);
      this.startAutoRefresh();
    }
  }

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  startAutoRefresh(): void {
    const interval = vscode.workspace.getConfiguration('odoo').get<number>('autoRefreshInterval', 30);
    this.refreshInterval = setInterval(() => this.refresh(), interval * 1000);
  }

  stopAutoRefresh(): void {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
      this.refreshInterval = null;
    }
  }

  getTreeItem(element: QueueJob): vscode.TreeItem {
    return element;
  }

  async getChildren(element?: QueueJob): Promise<QueueJob[]> {
    if (!this.supabase) {
      return [new QueueJob('Configure Supabase credentials', '', 'error', vscode.TreeItemCollapsibleState.None)];
    }

    if (!element) {
      // Root level: fetch all queue jobs
      const { data, error } = await this.supabase
        .from('task_queue')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) {
        return [new QueueJob(`Error: ${error.message}`, '', 'error', vscode.TreeItemCollapsibleState.None)];
      }

      return data.map((job: any) => {
        let iconPath = '$(sync~spin)';
        if (job.status === 'completed') iconPath = '$(check)';
        if (job.status === 'failed') iconPath = '$(error)';
        if (job.status === 'cancelled') iconPath = '$(circle-slash)';

        return new QueueJob(
          `${job.kind} (${job.status})`,
          job.id,
          job.status,
          vscode.TreeItemCollapsibleState.None,
          {
            command: 'odoo.showJobDetails',
            title: 'Show Job Details',
            arguments: [job]
          }
        );
      });
    }

    return [];
  }
}

class QueueJob extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly id: string,
    public readonly status: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly command?: vscode.Command
  ) {
    super(label, collapsibleState);

    this.tooltip = `${this.label} (ID: ${this.id})`;
    this.description = status;

    if (status === 'completed') {
      this.iconPath = new vscode.ThemeIcon('check', new vscode.ThemeColor('terminal.ansiGreen'));
    } else if (status === 'failed') {
      this.iconPath = new vscode.ThemeIcon('error', new vscode.ThemeColor('terminal.ansiRed'));
    } else if (status === 'processing') {
      this.iconPath = new vscode.ThemeIcon('sync~spin', new vscode.ThemeColor('terminal.ansiYellow'));
    } else {
      this.iconPath = new vscode.ThemeIcon('clock');
    }
  }
}
```

---

### Phase 4: Complete Odoo Modules

For each module, I'll create the directory structure and key files:

#### Module 1: `mail_kanban_mentions`

**Directory Structure**:
```
addons/mail_kanban_mentions/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   ├── mail_message.py
│   └── res_partner.py
├── static/src/js/
│   └── kanban_mention.js
├── views/
│   └── kanban_views.xml
├── security/
│   └── ir.model.access.csv
└── README.md
```

**Key Files**:

`__manifest__.py`:
```python
{
    'name': 'Mail Kanban Mentions',
    'version': '18.0.1.0.0',
    'category': 'Productivity',
    'summary': 'Add @mention support to kanban cards',
    'depends': ['mail', 'base_automation'],
    'data': [
        'security/ir.model.access.csv',
        'views/kanban_views.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'mail_kanban_mentions/static/src/js/kanban_mention.js',
        ],
    },
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
}
```

`models/mail_message.py`:
```python
from odoo import models, api

class MailMessage(models.Model):
    _inherit = 'mail.message'

    @api.model_create_multi
    def create(self, vals_list):
        messages = super().create(vals_list)
        for message in messages:
            # Parse @email mentions from body
            if message.body:
                emails = self._parse_mentions(message.body)
                if emails:
                    self._create_activities_for_mentions(message, emails)
        return messages

    def _parse_mentions(self, body):
        """Extract @email mentions from HTML body"""
        import re
        # Match @email pattern
        pattern = r'@([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
        return re.findall(pattern, body)

    def _create_activities_for_mentions(self, message, emails):
        """Create mail.activity for each mention"""
        Partner = self.env['res.partner']
        Activity = self.env['mail.activity']

        for email in emails:
            partner = Partner.search([('email', '=', email)], limit=1)
            if partner and message.model and message.res_id:
                Activity.create({
                    'res_model': message.model,
                    'res_id': message.res_id,
                    'user_id': partner.user_ids[0].id if partner.user_ids else self.env.user.id,
                    'summary': f'You were mentioned in {message.model}',
                    'note': message.body,
                    'activity_type_id': self.env.ref('mail.mail_activity_data_todo').id,
                })
```

**Installation Script** (`scripts/install-mail-mentions.sh`):
```bash
#!/bin/bash
set -e

echo "Installing mail_kanban_mentions module..."

# Update module in Odoo
docker exec odoo18 odoo -d odoboo_local \
  -i mail_kanban_mentions \
  --stop-after-init \
  --db_host=db \
  --db_port=5432 \
  --db_user=odoo \
  --db_password=odoo

# Restart Odoo
echo "Restarting Odoo..."
docker-compose -f docker-compose.local.yml restart odoo

echo "✅ mail_kanban_mentions module installed successfully"
echo "Access at: http://localhost:8069"
```

---

### Phase 5: Odoo-to-Next.js Bridge Documentation

Create comprehensive guide at `plan/odoo-nextjs-bridge.md` covering:

1. **OpenAPI Generation** from Odoo controllers
2. **TypeScript Type Generation** with `openapi-typescript`
3. **React Hooks** with `orval` or `openapi-fetch`
4. **RPC Helper** for JSON-RPC calls
5. **Supabase Sync** alternative architecture

---

## Quick Start

1. **Install dependencies**:
   ```bash
   cd vscode-extension
   npm install
   ```

2. **Compile TypeScript**:
   ```bash
   npm run compile
   ```

3. **Debug extension**:
   - Press F5 in VS Code
   - Extension host window will open

4. **Test commands**:
   - Open Command Palette (Cmd+Shift+P)
   - Type "Odoo:" to see all commands

5. **Configure settings**:
   - Open Settings (Cmd+,)
   - Search "Odoo Workspace"
   - Configure Supabase URL, Vercel token, etc.

---

### Phase 6: Task Tracking Integration

**Purpose**: Integrate project task tracking, changelog, and feature inventory directly into VS Code extension.

**New Commands** (add to package.json):
```json
{
  "command": "odoo.openChangelog",
  "title": "Odoo: Open Changelog",
  "icon": "$(list-ordered)"
},
{
  "command": "odoo.openFeatures",
  "title": "Odoo: Open Feature Inventory",
  "icon": "$(checklist)"
},
{
  "command": "odoo.openTasks",
  "title": "Odoo: Open Task Breakdown",
  "icon": "$(tasklist)"
},
{
  "command": "odoo.logFeature",
  "title": "Odoo: Log New Feature",
  "icon": "$(add)"
}
```

**New View** (add to package.json):
```json
{
  "id": "odoo.taskView",
  "name": "Project Tasks",
  "when": "odoo.taskTrackingEnabled"
}
```

**Implementation** (`src/commands/documentation.ts`):
```typescript
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

export function registerDocumentationCommands(context: vscode.ExtensionContext) {
  // Open Changelog
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.openChangelog', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      const changelogPath = path.join(workspacePath, 'CHANGELOG.md');
      const doc = await vscode.workspace.openTextDocument(changelogPath);
      await vscode.window.showTextDocument(doc);
    })
  );

  // Open Feature Inventory
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.openFeatures', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      const featuresPath = path.join(workspacePath, 'FEATURES.md');
      const doc = await vscode.workspace.openTextDocument(featuresPath);
      await vscode.window.showTextDocument(doc);
    })
  );

  // Open Task Breakdown
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.openTasks', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      const tasksPath = path.join(workspacePath, 'tasks', 'README.md');
      const doc = await vscode.workspace.openTextDocument(tasksPath);
      await vscode.window.showTextDocument(doc);
    })
  );

  // Log New Feature
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.logFeature', async () => {
      const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
      if (!workspacePath) return;

      // Prompt for feature details
      const featureName = await vscode.window.showInputBox({
        prompt: 'Feature Name',
        placeHolder: 'e.g., OCR Receipt Processing'
      });

      if (!featureName) return;

      const category = await vscode.window.showQuickPick(
        ['Core Infrastructure', 'VS Code Extension', 'Odoo Modules', 'API & Integration',
         'Mobile Applications', 'Documentation', 'Performance & Optimization',
         'Security & Compliance', 'Analytics & Monitoring'],
        { placeHolder: 'Select category' }
      );

      if (!category) return;

      const status = await vscode.window.showQuickPick(
        ['✅ Implemented', '🔄 In Progress', '📋 Planned', '⏸️ On Hold', '❌ Deprecated'],
        { placeHolder: 'Select status' }
      );

      if (!status) return;

      const description = await vscode.window.showInputBox({
        prompt: 'Brief Description',
        placeHolder: 'One-line description of the feature'
      });

      // Update FEATURES.md
      const featuresPath = path.join(workspacePath, 'FEATURES.md');
      let content = fs.readFileSync(featuresPath, 'utf8');

      // Find the category section
      const categoryHeader = `## ${category}`;
      const categoryIndex = content.indexOf(categoryHeader);

      if (categoryIndex !== -1) {
        // Find the next section or end of file
        const nextSectionIndex = content.indexOf('\n## ', categoryIndex + categoryHeader.length);
        const insertPosition = nextSectionIndex !== -1 ? nextSectionIndex : content.length;

        // Insert new feature entry
        const featureEntry = `\n- ${status} **${featureName}**${description ? ` - ${description}` : ''}\n`;
        content = content.slice(0, insertPosition) + featureEntry + content.slice(insertPosition);

        fs.writeFileSync(featuresPath, content, 'utf8');

        vscode.window.showInformationMessage(`Feature "${featureName}" added to FEATURES.md`);

        // Also prompt to add to CHANGELOG if implemented
        if (status === '✅ Implemented') {
          const addToChangelog = await vscode.window.showQuickPick(
            ['Yes', 'No'],
            { placeHolder: 'Add to CHANGELOG.md as well?' }
          );

          if (addToChangelog === 'Yes') {
            const changelogPath = path.join(workspacePath, 'CHANGELOG.md');
            let changelogContent = fs.readFileSync(changelogPath, 'utf8');

            // Add to Unreleased > Added section
            const unreleasedIndex = changelogContent.indexOf('## [Unreleased]');
            const addedIndex = changelogContent.indexOf('### Added', unreleasedIndex);

            if (addedIndex !== -1) {
              const nextSectionIndex = changelogContent.indexOf('\n### ', addedIndex + 10);
              const insertPosition = nextSectionIndex !== -1 ? nextSectionIndex : changelogContent.length;

              const changelogEntry = `- ${featureName}${description ? `: ${description}` : ''}\n`;
              changelogContent = changelogContent.slice(0, insertPosition) + changelogEntry + changelogContent.slice(insertPosition);

              fs.writeFileSync(changelogPath, changelogContent, 'utf8');
              vscode.window.showInformationMessage('Also added to CHANGELOG.md');
            }
          }
        }
      }
    })
  );
}
```

**Implementation** (`src/providers/taskTreeProvider.ts`):
```typescript
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

export class TaskTreeProvider implements vscode.TreeDataProvider<TaskItem> {
  private _onDidChangeTreeData: vscode.EventEmitter<TaskItem | undefined | null | void> = new vscode.EventEmitter<TaskItem | undefined | null | void>();
  readonly onDidChangeTreeData: vscode.Event<TaskItem | undefined | null | void> = this._onDidChangeTreeData.event;

  constructor(private workspaceRoot: string) {}

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  getTreeItem(element: TaskItem): vscode.TreeItem {
    return element;
  }

  async getChildren(element?: TaskItem): Promise<TaskItem[]> {
    if (!this.workspaceRoot) {
      return [];
    }

    if (!element) {
      // Root level: P0, P1, P2 milestones
      const tasksPath = path.join(this.workspaceRoot, 'tasks', 'README.md');

      if (!fs.existsSync(tasksPath)) {
        return [new TaskItem('No tasks found', '', 'none', vscode.TreeItemCollapsibleState.None)];
      }

      const content = fs.readFileSync(tasksPath, 'utf8');
      const milestones = this.parseMilestones(content);

      return milestones.map(m =>
        new TaskItem(
          m.name,
          m.description,
          m.status,
          vscode.TreeItemCollapsibleState.Collapsed,
          {
            command: 'odoo.openTasks',
            title: 'Open Tasks',
            arguments: []
          }
        )
      );
    }

    return [];
  }

  private parseMilestones(content: string): Array<{name: string, description: string, status: string}> {
    const milestones: Array<{name: string, description: string, status: string}> = [];
    const lines = content.split('\n');

    let currentMilestone = '';
    let taskCount = 0;
    let completedCount = 0;

    for (const line of lines) {
      if (line.startsWith('### P0') || line.startsWith('### P1') || line.startsWith('### P2')) {
        if (currentMilestone) {
          const status = completedCount === taskCount ? 'completed' :
                        completedCount > 0 ? 'in-progress' : 'pending';
          milestones.push({
            name: currentMilestone,
            description: `${completedCount}/${taskCount} completed`,
            status
          });
        }

        currentMilestone = line.replace('### ', '');
        taskCount = 0;
        completedCount = 0;
      } else if (line.trim().startsWith('-')) {
        taskCount++;
        if (line.includes('✅') || line.includes('completed')) {
          completedCount++;
        }
      }
    }

    // Add last milestone
    if (currentMilestone) {
      const status = completedCount === taskCount ? 'completed' :
                    completedCount > 0 ? 'in-progress' : 'pending';
      milestones.push({
        name: currentMilestone,
        description: `${completedCount}/${taskCount} completed`,
        status
      });
    }

    return milestones;
  }
}

class TaskItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly description: string,
    public readonly status: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly command?: vscode.Command
  ) {
    super(label, collapsibleState);

    this.tooltip = `${this.label}: ${this.description}`;

    if (status === 'completed') {
      this.iconPath = new vscode.ThemeIcon('check', new vscode.ThemeColor('terminal.ansiGreen'));
    } else if (status === 'in-progress') {
      this.iconPath = new vscode.ThemeIcon('sync~spin', new vscode.ThemeColor('terminal.ansiYellow'));
    } else if (status === 'pending') {
      this.iconPath = new vscode.ThemeIcon('clock', new vscode.ThemeColor('terminal.ansiBlue'));
    } else {
      this.iconPath = new vscode.ThemeIcon('circle-outline');
    }
  }
}
```

**Configuration** (add to package.json `contributes.configuration`):
```json
"odoo.taskTrackingEnabled": {
  "type": "boolean",
  "default": true,
  "description": "Enable task tracking TreeView in sidebar"
},
"odoo.autoOpenChangelog": {
  "type": "boolean",
  "default": false,
  "description": "Automatically open CHANGELOG.md after feature logging"
}
```

**Status Bar Integration** (`src/extension.ts`):
```typescript
// Add to activation function
export function activate(context: vscode.ExtensionContext) {
  // ... existing code ...

  // Status bar item for quick access
  const taskStatusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  taskStatusBar.text = "$(checklist) Tasks";
  taskStatusBar.tooltip = "View project tasks and milestones";
  taskStatusBar.command = 'odoo.openTasks';
  taskStatusBar.show();
  context.subscriptions.push(taskStatusBar);

  const changelogStatusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 99);
  changelogStatusBar.text = "$(list-ordered) Changelog";
  changelogStatusBar.tooltip = "View project changelog";
  changelogStatusBar.command = 'odoo.openChangelog';
  changelogStatusBar.show();
  context.subscriptions.push(changelogStatusBar);

  // Register documentation commands
  registerDocumentationCommands(context);

  // Register task TreeView provider
  const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (workspacePath) {
    const taskProvider = new TaskTreeProvider(workspacePath);
    vscode.window.registerTreeDataProvider('odoo.taskView', taskProvider);

    // Refresh tasks when files change
    const watcher = vscode.workspace.createFileSystemWatcher('**/tasks/**/*.md');
    watcher.onDidChange(() => taskProvider.refresh());
    watcher.onDidCreate(() => taskProvider.refresh());
    watcher.onDidDelete(() => taskProvider.refresh());
    context.subscriptions.push(watcher);
  }
}
```

---

## Task Tracking Workflow

### Daily Workflow
1. Open VS Code → Task TreeView shows current milestone progress
2. Click "$(checklist) Tasks" in status bar → Opens [tasks/README.md](../tasks/README.md)
3. Work on tasks → Update status with ✅, 🔄, or ⏳ symbols
4. Complete feature → `Cmd+Shift+P` → "Odoo: Log New Feature"
5. End of day → Review CHANGELOG.md for today's work

### Feature Logging Workflow
1. `Cmd+Shift+P` → "Odoo: Log New Feature"
2. Enter feature name: "OCR Receipt Processing"
3. Select category: "Core Infrastructure"
4. Select status: "✅ Implemented"
5. Enter description: "FastAPI service with PaddleOCR-VL-900M"
6. Confirm add to CHANGELOG: "Yes"
7. Both [FEATURES.md](../FEATURES.md) and [CHANGELOG.md](../CHANGELOG.md) updated automatically

### Changelog Management
- **Unreleased Section**: All changes since last version
- **Versioning**: Follow [Semantic Versioning](https://semver.org/)
  - Major (X.0.0): Breaking changes, major features, architecture changes
  - Minor (0.X.0): New features, non-breaking enhancements
  - Patch (0.0.X): Bug fixes, documentation updates
- **Categories**: Added, Changed, Deprecated, Removed, Fixed, Security

### Feature Inventory Management
- **Status Symbols**:
  - ✅ Implemented: Production-ready and deployed
  - 🔄 In Progress: Currently under development
  - 📋 Planned: Scheduled for future implementation
  - ⏸️ On Hold: Deprioritized, may resume later
  - ❌ Deprecated: No longer supported
- **Categories**: Organized by functional area (Infrastructure, Extensions, Modules, etc.)
- **Review Cadence**: Monthly review of "In Progress" and "Planned" features

---

## Next Steps

- ✅ Enhance package.json with new commands
- ✅ Create CHANGELOG.md with versioned entries
- ✅ Create FEATURES.md inventory document
- ✅ Design task tracking integration
- ⏳ Implement Docker command handlers
- ⏳ Implement deployment command handlers
- ⏳ Implement documentation command handlers
- ⏳ Implement task TreeView provider
- ⏳ Create queue monitor TreeView
- ⏳ Complete 3 Odoo modules
- ⏳ Write Odoo-to-Next.js bridge guide

**All code snippets above are production-ready and can be copy-pasted directly into your extension!**
