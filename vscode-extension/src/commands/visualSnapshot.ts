import * as vscode from 'vscode';
import { chromium } from 'playwright';
import * as fs from 'fs';
import * as path from 'path';
import ssim from 'image-ssim';

export async function runSnapshot() {
  const config = vscode.workspace.getConfiguration();
  const baseUrl = config.get<string>('qa.baseUrl') || 'http://localhost:8069';
  const visualApiUrl = config.get<string>('qa.visualApiUrl');

  const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!workspaceFolder) {
    vscode.window.showErrorMessage('No workspace folder open');
    return;
  }

  const snapshotsDir = path.join(workspaceFolder, '.snapshots');
  if (!fs.existsSync(snapshotsDir)) {
    fs.mkdirSync(snapshotsDir, { recursive: true });
  }

  // Ask user for path to capture
  const pagePath = await vscode.window.showInputBox({
    prompt: 'Enter page path to capture',
    value: '/',
    placeHolder: '/',
  });

  if (!pagePath) {
    return;
  }

  const sanitizedName = pagePath.replace(/[^\w]/g, '_') || 'home';
  const baselinePath = path.join(snapshotsDir, `${sanitizedName}.png`);
  const currentPath = path.join(snapshotsDir, `${sanitizedName}.current.png`);

  vscode.window.showInformationMessage('Capturing screenshot...');

  try {
    // Launch browser and capture screenshot
    const browser = await chromium.launch();
    const page = await browser.newPage({
      viewport: { width: 1280, height: 800 },
    });

    await page.goto(baseUrl + pagePath, { waitUntil: 'networkidle' });
    await page.screenshot({ path: currentPath, fullPage: true });
    await browser.close();

    // If no baseline exists, create it
    if (!fs.existsSync(baselinePath)) {
      fs.copyFileSync(currentPath, baselinePath);
      vscode.window.showInformationMessage(`✅ Baseline created: ${baselinePath}`);
      return;
    }

    // Compare with baseline using SSIM
    const baselineBuffer = fs.readFileSync(baselinePath);
    const currentBuffer = fs.readFileSync(currentPath);

    const ssimResult = ssim.compare(baselineBuffer as any, currentBuffer as any) as any;
    const diffPercent = Number(((1 - ssimResult.mssim) * 100).toFixed(3));

    // If visual API is configured, use it for advanced comparison
    if (visualApiUrl) {
      vscode.window.showInformationMessage('Running advanced visual comparison with OCR...');

      const formData = new FormData();
      formData.append('baseline', new Blob([baselineBuffer]));
      formData.append('candidate', new Blob([currentBuffer]));
      formData.append('meta', JSON.stringify({ path: pagePath, name: sanitizedName }));

      try {
        const response = await fetch(`${visualApiUrl}/compare`, {
          method: 'POST',
          body: formData,
        });

        const result = (await response.json()) as {
          verdict: boolean;
          metrics: { ssim: number; lpips: number; clip: number };
          json_diff?: Record<string, any>;
        };
        const verdict = result.verdict ? '✅ PASS' : '❌ FAIL';

        vscode.window.showInformationMessage(
          `${verdict} Visual QA: SSIM=${result.metrics.ssim.toFixed(4)}, LPIPS=${result.metrics.lpips.toFixed(4)}, CLIP=${result.metrics.clip.toFixed(4)}`
        );

        // Show detailed diff if available
        if (result.json_diff && Object.keys(result.json_diff).length > 0) {
          const diffDoc = await vscode.workspace.openTextDocument({
            language: 'json',
            content: JSON.stringify(result.json_diff, null, 2),
          });
          await vscode.window.showTextDocument(diffDoc, { viewColumn: vscode.ViewColumn.Beside });
        }
      } catch (error) {
        vscode.window.showWarningMessage(`Advanced comparison failed: ${error}. Falling back to SSIM only.`);
        vscode.window.showInformationMessage(`SSIM diff: ${diffPercent}% (lower is better). Files saved in .snapshots/`);
      }
    } else {
      // Just show SSIM result
      const threshold = 2.0; // 2% difference threshold
      const verdict = diffPercent < threshold ? '✅ PASS' : '❌ FAIL';
      vscode.window.showInformationMessage(`${verdict} SSIM diff: ${diffPercent}% (threshold: ${threshold}%)`);
    }
  } catch (error) {
    vscode.window.showErrorMessage(`Visual snapshot error: ${error}`);
  }
}
