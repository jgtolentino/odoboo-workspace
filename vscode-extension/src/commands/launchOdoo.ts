import * as vscode from 'vscode';
import { spawn } from 'child_process';

export async function launchOdoo() {
  const config = vscode.workspace.getConfiguration();
  const pythonPath = config.get<string>('odoo.pythonPath') || 'python';
  const odooBin = config.get<string>('odoo.bin') || 'odoo';
  const odooConfig = config.get<string>('odoo.config') || 'odoo.conf';
  const addonsPath = config.get<string>('odoo.addonsPath') || 'addons';

  // Create terminal for Odoo
  const terminal = vscode.window.createTerminal({
    name: 'Odoo Dev Server',
    iconPath: new vscode.ThemeIcon('play'),
  });

  terminal.sendText(`${pythonPath} ${odooBin} -c ${odooConfig} --addons-path=${addonsPath} --dev=all`);
  terminal.show();

  vscode.window.showInformationMessage('Odoo dev server starting...');
}
