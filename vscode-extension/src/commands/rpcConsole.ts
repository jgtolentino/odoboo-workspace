import * as vscode from 'vscode';

export async function openRpcConsole() {
  const url = await vscode.window.showInputBox({
    prompt: 'Odoo URL',
    value: 'http://localhost:8069',
    placeHolder: 'http://localhost:8069',
  });

  if (!url) {
    return;
  }

  const db = await vscode.window.showInputBox({
    prompt: 'Database name',
    value: 'odoo',
    placeHolder: 'odoo',
  });

  if (!db) {
    return;
  }

  const login = await vscode.window.showInputBox({
    prompt: 'Login (email)',
    placeHolder: 'admin@example.com',
  });

  if (!login) {
    return;
  }

  const password = await vscode.window.showInputBox({
    prompt: 'Password',
    password: true,
  });

  if (!password) {
    return;
  }

  // Create webview panel for RPC console
  const panel = vscode.window.createWebviewPanel(
    'odooRpcConsole',
    'Odoo RPC Console',
    vscode.ViewColumn.Beside,
    {
      enableScripts: true,
      retainContextWhenHidden: true,
    }
  );

  // Authenticate with Odoo
  let uid: number | null = null;
  try {
    const authResponse = await fetch(`${url}/jsonrpc`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'call',
        id: 1,
        params: {
          service: 'common',
          method: 'login',
          args: [db, login, password],
        },
      }),
    });

    const authData = (await authResponse.json()) as { result: number };
    uid = authData.result;

    if (!uid) {
      vscode.window.showErrorMessage('Authentication failed. Check credentials.');
      panel.dispose();
      return;
    }
  } catch (error) {
    vscode.window.showErrorMessage(`Connection error: ${error}`);
    panel.dispose();
    return;
  }

  // Handle messages from webview
  panel.webview.onDidReceiveMessage(async (message) => {
    if (message.type !== 'rpc') {
      return;
    }

    try {
      const response = await fetch(`${url}/jsonrpc`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'call',
          id: Date.now(),
          params: {
            service: 'object',
            method: 'execute_kw',
            args: [db, uid, password, message.model, message.method, message.args || [], message.kwargs || {}],
          },
        }),
      });

      const data = await response.json();
      panel.webview.postMessage({ type: 'result', data });
    } catch (error) {
      panel.webview.postMessage({ type: 'error', error: String(error) });
    }
  });

  // Set webview HTML content
  panel.webview.html = getRpcConsoleHtml(db, String(uid));
}

function getRpcConsoleHtml(db: string, uid: string): string {
  return `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; padding: 20px; background: #1e1e1e; color: #d4d4d4; }
    h2 { color: #4ec9b0; }
    input, textarea, button {
      width: 100%;
      margin: 8px 0;
      padding: 10px;
      background: #2d2d2d;
      color: #d4d4d4;
      border: 1px solid #3e3e3e;
      border-radius: 4px;
      font-family: 'Consolas', monospace;
    }
    button {
      background: #0e639c;
      color: white;
      cursor: pointer;
      width: auto;
      padding: 10px 20px;
    }
    button:hover { background: #1177bb; }
    pre {
      background: #252526;
      padding: 15px;
      border-radius: 4px;
      overflow: auto;
      max-height: 400px;
    }
    .label { font-weight: bold; margin-top: 12px; display: block; }
  </style>
</head>
<body>
  <h2>🔌 Odoo RPC Console</h2>
  <p>Connected to: <strong>${db}</strong> (UID: ${uid})</p>

  <label class="label">Model:</label>
  <input id="model" placeholder="res.partner" value="res.partner"/>

  <label class="label">Method:</label>
  <input id="method" placeholder="search_read" value="search_read"/>

  <label class="label">Args (JSON array):</label>
  <textarea id="args" rows="3" placeholder='[[["is_company","=",true]], ["name","email","phone"]]'>[[["is_company","=",true]], ["name","email","phone"]]</textarea>

  <label class="label">Kwargs (JSON object):</label>
  <textarea id="kwargs" rows="3" placeholder='{"limit": 5}'>{"limit": 5}</textarea>

  <br/>
  <button onclick="sendRpc()">▶️ Execute</button>

  <h3>Response:</h3>
  <pre id="output">Results will appear here...</pre>

  <script>
    const vscode = acquireVsCodeApi();

    function sendRpc() {
      const model = document.getElementById('model').value;
      const method = document.getElementById('method').value;
      const args = JSON.parse(document.getElementById('args').value || '[]');
      const kwargs = JSON.parse(document.getElementById('kwargs').value || '{}');

      vscode.postMessage({
        type: 'rpc',
        model,
        method,
        args,
        kwargs
      });

      document.getElementById('output').textContent = 'Executing...';
    }

    window.addEventListener('message', event => {
      const message = event.data;
      const output = document.getElementById('output');

      if (message.type === 'result') {
        output.textContent = JSON.stringify(message.data, null, 2);
      } else if (message.type === 'error') {
        output.textContent = 'Error: ' + message.error;
      }
    });
  </script>
</body>
</html>`;
}
