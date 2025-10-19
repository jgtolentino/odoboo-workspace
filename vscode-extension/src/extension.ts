import * as vscode from 'vscode';
import { launchOdoo } from './commands/launchOdoo';
import { openRpcConsole } from './commands/rpcConsole';
import { runSchemaGuard } from './commands/schemaGuard';
import { runSnapshot } from './commands/visualSnapshot';
import { runImpactedTests } from './commands/testImpact';
import { checkDeploymentStatus } from './commands/deploymentStatus';
import { DeploymentStatusProvider } from './providers/DeploymentStatusProvider';

export function activate(context: vscode.ExtensionContext) {
  console.log('Odoo Workspace (Supabase-Ops) extension activated');

  // Register deployment status tree view
  const deploymentProvider = new DeploymentStatusProvider();
  vscode.window.registerTreeDataProvider('deploymentStatus', deploymentProvider);

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('odoo.launch', launchOdoo),
    vscode.commands.registerCommand('odoo.rpcConsole', openRpcConsole),
    vscode.commands.registerCommand('db.schemaGuard', runSchemaGuard),
    vscode.commands.registerCommand('qa.snapshot', runSnapshot),
    vscode.commands.registerCommand('test.impact', runImpactedTests),
    vscode.commands.registerCommand('platform.checkStatus', () => checkDeploymentStatus(deploymentProvider))
  );

  // Auto-refresh deployment status every 30 seconds
  setInterval(() => {
    deploymentProvider.refresh();
  }, 30000);

  vscode.window.showInformationMessage('Odoo Workspace extension loaded! Use Command Palette (Cmd+Shift+P) to access features.');
}

export function deactivate() {
  console.log('Odoo Workspace extension deactivated');
}
