import { Octokit } from '@octokit/rest';

export interface GitHubWorkflowRun {
  id: number;
  name: string;
  status: 'queued' | 'in_progress' | 'completed';
  conclusion: 'success' | 'failure' | 'cancelled' | 'skipped' | null;
  created_at: string;
  updated_at: string;
  html_url: string;
}

export interface GitHubStatus {
  status: 'healthy' | 'error' | 'unknown';
  latestWorkflow: GitHubWorkflowRun | null;
  repoName: string;
  branch: string;
  runTime: string | null;
}

export class GitHubProvider {
  private octokit: Octokit | null = null;
  private owner: string | null = null;
  private repo: string | null = null;

  constructor(token?: string, repo?: string) {
    if (token) {
      this.octokit = new Octokit({ auth: token });
    }

    if (repo) {
      // Parse "owner/repo" format
      const parts = repo.split('/');
      if (parts.length === 2) {
        this.owner = parts[0];
        this.repo = parts[1];
      }
    }
  }

  async getStatus(): Promise<GitHubStatus> {
    if (!this.octokit || !this.owner || !this.repo) {
      return {
        status: 'unknown',
        latestWorkflow: null,
        repoName: 'Not configured',
        branch: 'main',
        runTime: null,
      };
    }

    try {
      // Get latest workflow runs
      const { data } = await this.octokit.rest.actions.listWorkflowRunsForRepo({
        owner: this.owner,
        repo: this.repo,
        per_page: 1,
        branch: 'main',
      });

      const run = data.workflow_runs?.[0];

      if (!run) {
        return {
          status: 'unknown',
          latestWorkflow: null,
          repoName: `${this.owner}/${this.repo}`,
          branch: 'main',
          runTime: null,
        };
      }

      const workflowRun: GitHubWorkflowRun = {
        id: run.id,
        name: run.name || 'Workflow',
        status: run.status as any,
        conclusion: run.conclusion as any,
        created_at: run.created_at,
        updated_at: run.updated_at,
        html_url: run.html_url,
      };

      let status: 'healthy' | 'error' | 'unknown' = 'unknown';
      if (run.status === 'completed') {
        status = run.conclusion === 'success' ? 'healthy' : 'error';
      } else if (run.status === 'in_progress') {
        status = 'healthy'; // Running is considered healthy
      }

      return {
        status,
        latestWorkflow: workflowRun,
        repoName: `${this.owner}/${this.repo}`,
        branch: 'main',
        runTime: new Date(run.updated_at).toLocaleString(),
      };
    } catch (error) {
      console.error('GitHub provider error:', error);
      return {
        status: 'error',
        latestWorkflow: null,
        repoName: `${this.owner}/${this.repo}`,
        branch: 'main',
        runTime: null,
      };
    }
  }
}
