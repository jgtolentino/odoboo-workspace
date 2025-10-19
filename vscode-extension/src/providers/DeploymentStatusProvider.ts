import * as vscode from 'vscode';
import { VercelProvider, VercelStatus } from './VercelProvider';
import { SupabaseProvider, SupabaseStatus } from './SupabaseProvider';
import { GitHubProvider, GitHubStatus } from './GitHubProvider';
import { DigitalOceanProvider, DOStatus } from './DigitalOceanProvider';

export class DeploymentItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly platform?: string,
    public readonly status?: 'healthy' | 'error' | 'unknown',
    public readonly description?: string,
    public readonly url?: string
  ) {
    super(label, collapsibleState);

    if (status) {
      this.iconPath = new vscode.ThemeIcon(
        status === 'healthy' ? 'check' : status === 'error' ? 'error' : 'warning',
        new vscode.ThemeColor(
          status === 'healthy'
            ? 'testing.iconPassed'
            : status === 'error'
            ? 'testing.iconFailed'
            : 'testing.iconQueued'
        )
      );
    }

    if (url) {
      this.command = {
        command: 'vscode.open',
        title: 'Open URL',
        arguments: [vscode.Uri.parse(url)],
      };
    }

    this.tooltip = description;
    this.contextValue = platform;
  }
}

export class DeploymentStatusProvider implements vscode.TreeDataProvider<DeploymentItem> {
  private _onDidChangeTreeData: vscode.EventEmitter<DeploymentItem | undefined | null | void> =
    new vscode.EventEmitter<DeploymentItem | undefined | null | void>();
  readonly onDidChangeTreeData: vscode.Event<DeploymentItem | undefined | null | void> =
    this._onDidChangeTreeData.event;

  private vercelProvider: VercelProvider;
  private supabaseProvider: SupabaseProvider;
  private githubProvider: GitHubProvider;
  private doProvider: DigitalOceanProvider;

  constructor() {
    const config = vscode.workspace.getConfiguration();

    // Initialize providers with configuration
    this.vercelProvider = new VercelProvider(
      config.get('vercel.token'),
      config.get('vercel.teamId'),
      config.get('vercel.projectId')
    );

    this.supabaseProvider = new SupabaseProvider(
      config.get('supabase.url'),
      config.get('supabase.serviceRoleKey'),
      config.get('supabase.projectRef')
    );

    this.githubProvider = new GitHubProvider(
      config.get('github.token'),
      config.get('github.repo')
    );

    this.doProvider = new DigitalOceanProvider(
      config.get('digitalocean.token'),
      config.get('digitalocean.appId')
    );
  }

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  getTreeItem(element: DeploymentItem): vscode.TreeItem {
    return element;
  }

  async getChildren(element?: DeploymentItem): Promise<DeploymentItem[]> {
    if (!element) {
      // Root level - show platform categories
      return [
        new DeploymentItem('Vercel', vscode.TreeItemCollapsibleState.Expanded, 'vercel'),
        new DeploymentItem('Supabase', vscode.TreeItemCollapsibleState.Expanded, 'supabase'),
        new DeploymentItem('GitHub Actions', vscode.TreeItemCollapsibleState.Expanded, 'github'),
        new DeploymentItem('DigitalOcean', vscode.TreeItemCollapsibleState.Expanded, 'digitalocean'),
      ];
    }

    // Platform-specific details
    switch (element.platform) {
      case 'vercel':
        return this.getVercelChildren();
      case 'supabase':
        return this.getSupabaseChildren();
      case 'github':
        return this.getGitHubChildren();
      case 'digitalocean':
        return this.getDigitalOceanChildren();
      default:
        return [];
    }
  }

  private async getVercelChildren(): Promise<DeploymentItem[]> {
    const status = await this.vercelProvider.getStatus();
    const items: DeploymentItem[] = [];

    items.push(
      new DeploymentItem(
        'Status',
        vscode.TreeItemCollapsibleState.None,
        'vercel-status',
        status.status,
        status.status.toUpperCase()
      )
    );

    if (status.projectName) {
      items.push(
        new DeploymentItem(
          `Project: ${status.projectName}`,
          vscode.TreeItemCollapsibleState.None,
          'vercel-project'
        )
      );
    }

    if (status.url) {
      items.push(
        new DeploymentItem(
          'Production URL',
          vscode.TreeItemCollapsibleState.None,
          'vercel-url',
          undefined,
          status.url,
          status.url
        )
      );
    }

    if (status.deployTime) {
      items.push(
        new DeploymentItem(
          `Deployed: ${status.deployTime}`,
          vscode.TreeItemCollapsibleState.None,
          'vercel-time'
        )
      );
    }

    if (status.latestDeployment) {
      items.push(
        new DeploymentItem(
          `State: ${status.latestDeployment.readyState}`,
          vscode.TreeItemCollapsibleState.None,
          'vercel-state'
        )
      );
    }

    return items;
  }

  private async getSupabaseChildren(): Promise<DeploymentItem[]> {
    const status = await this.supabaseProvider.getStatus();
    const items: DeploymentItem[] = [];

    items.push(
      new DeploymentItem(
        'Status',
        vscode.TreeItemCollapsibleState.None,
        'supabase-status',
        status.status,
        status.status.toUpperCase()
      )
    );

    items.push(
      new DeploymentItem(
        `Project: ${status.projectRef}`,
        vscode.TreeItemCollapsibleState.None,
        'supabase-project'
      )
    );

    items.push(
      new DeploymentItem(
        `Functions: ${status.functionsCount}`,
        vscode.TreeItemCollapsibleState.None,
        'supabase-functions'
      )
    );

    if (status.lastMigration) {
      items.push(
        new DeploymentItem(
          `Last Migration: ${status.lastMigration}`,
          vscode.TreeItemCollapsibleState.None,
          'supabase-migration'
        )
      );
    }

    if (status.dbSize) {
      items.push(
        new DeploymentItem(
          `DB Size: ${status.dbSize}`,
          vscode.TreeItemCollapsibleState.None,
          'supabase-size'
        )
      );
    }

    return items;
  }

  private async getGitHubChildren(): Promise<DeploymentItem[]> {
    const status = await this.githubProvider.getStatus();
    const items: DeploymentItem[] = [];

    items.push(
      new DeploymentItem(
        'Status',
        vscode.TreeItemCollapsibleState.None,
        'github-status',
        status.status,
        status.status.toUpperCase()
      )
    );

    items.push(
      new DeploymentItem(
        `Repo: ${status.repoName}`,
        vscode.TreeItemCollapsibleState.None,
        'github-repo'
      )
    );

    items.push(
      new DeploymentItem(
        `Branch: ${status.branch}`,
        vscode.TreeItemCollapsibleState.None,
        'github-branch'
      )
    );

    if (status.latestWorkflow) {
      const workflow = status.latestWorkflow;
      items.push(
        new DeploymentItem(
          `Workflow: ${workflow.name}`,
          vscode.TreeItemCollapsibleState.None,
          'github-workflow',
          undefined,
          undefined,
          workflow.html_url
        )
      );

      items.push(
        new DeploymentItem(
          `Status: ${workflow.status}`,
          vscode.TreeItemCollapsibleState.None,
          'github-workflow-status'
        )
      );

      if (workflow.conclusion) {
        items.push(
          new DeploymentItem(
            `Conclusion: ${workflow.conclusion}`,
            vscode.TreeItemCollapsibleState.None,
            'github-conclusion'
          )
        );
      }
    }

    if (status.runTime) {
      items.push(
        new DeploymentItem(
          `Updated: ${status.runTime}`,
          vscode.TreeItemCollapsibleState.None,
          'github-time'
        )
      );
    }

    return items;
  }

  private async getDigitalOceanChildren(): Promise<DeploymentItem[]> {
    const status = await this.doProvider.getStatus();
    const items: DeploymentItem[] = [];

    items.push(
      new DeploymentItem(
        'Status',
        vscode.TreeItemCollapsibleState.None,
        'do-status',
        status.status,
        status.status.toUpperCase()
      )
    );

    items.push(
      new DeploymentItem(
        `App: ${status.appName}`,
        vscode.TreeItemCollapsibleState.None,
        'do-app'
      )
    );

    items.push(
      new DeploymentItem(
        `Region: ${status.region}`,
        vscode.TreeItemCollapsibleState.None,
        'do-region'
      )
    );

    if (status.liveUrl) {
      items.push(
        new DeploymentItem(
          'Live URL',
          vscode.TreeItemCollapsibleState.None,
          'do-url',
          undefined,
          status.liveUrl,
          status.liveUrl
        )
      );
    }

    if (status.latestDeployment) {
      const deploy = status.latestDeployment;
      items.push(
        new DeploymentItem(
          `Phase: ${deploy.phase}`,
          vscode.TreeItemCollapsibleState.None,
          'do-phase'
        )
      );

      items.push(
        new DeploymentItem(
          `Cause: ${deploy.cause}`,
          vscode.TreeItemCollapsibleState.None,
          'do-cause'
        )
      );
    }

    if (status.deployTime) {
      items.push(
        new DeploymentItem(
          `Deployed: ${status.deployTime}`,
          vscode.TreeItemCollapsibleState.None,
          'do-time'
        )
      );
    }

    return items;
  }
}
