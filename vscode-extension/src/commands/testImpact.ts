import * as vscode from 'vscode';

export async function runImpactedTests() {
  const choice = await vscode.window.showQuickPick(
    [
      { label: 'Jest (JavaScript/TypeScript)', value: 'jest' },
      { label: 'Pytest (Python)', value: 'pytest' },
    ],
    {
      placeHolder: 'Select test runner',
    }
  );

  if (!choice) {
    return;
  }

  const terminal = vscode.window.createTerminal({
    name: 'Impacted Tests',
    iconPath: new vscode.ThemeIcon('beaker'),
  });

  if (choice.value === 'jest') {
    terminal.sendText('npx jest --onlyChanged --coverage');
  } else {
    terminal.sendText('pytest --testmon --cov');
  }

  terminal.show();
  vscode.window.showInformationMessage(`Running impacted tests with ${choice.label}...`);
}
