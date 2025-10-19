import * as vscode from 'vscode';
import { DeploymentStatusProvider } from '../providers/DeploymentStatusProvider';

export async function checkDeploymentStatus(provider: DeploymentStatusProvider) {
  vscode.window.showInformationMessage('Refreshing deployment status...');
  await provider.refresh();
  vscode.window.showInformationMessage('Deployment status updated!');
}
