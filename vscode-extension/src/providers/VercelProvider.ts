export interface VercelDeployment {
  uid: string;
  name: string;
  url: string;
  state: 'READY' | 'ERROR' | 'BUILDING' | 'QUEUED' | 'CANCELED';
  createdAt: number;
  readyState: string;
  target: 'production' | 'preview' | 'development';
}

export interface VercelStatus {
  status: 'healthy' | 'error' | 'unknown';
  latestDeployment: VercelDeployment | null;
  projectName: string;
  url: string | null;
  deployTime: string | null;
}

export class VercelProvider {
  private token: string | null = null;
  private teamId: string | null = null;
  private projectId: string | null = null;

  constructor(token?: string, teamId?: string, projectId?: string) {
    this.token = token || process.env.VERCEL_TOKEN || null;
    this.teamId = teamId || null;
    this.projectId = projectId || null;
  }

  async getStatus(): Promise<VercelStatus> {
    if (!this.token || !this.projectId) {
      return {
        status: 'unknown',
        latestDeployment: null,
        projectName: 'Not configured',
        url: null,
        deployTime: null,
      };
    }

    try {
      const deploymentsUrl = `https://api.vercel.com/v6/deployments?projectId=${this.projectId}&limit=1`;
      const headers = {
        Authorization: `Bearer ${this.token}`,
        ...(this.teamId ? { 'X-Team-Id': this.teamId } : {}),
      };

      const response = await fetch(deploymentsUrl, { headers });

      if (!response.ok) {
        return {
          status: 'error',
          latestDeployment: null,
          projectName: this.projectId,
          url: null,
          deployTime: null,
        };
      }

      const data = (await response.json()) as { deployments?: VercelDeployment[] };
      const deployment = data.deployments?.[0];

      if (!deployment) {
        return {
          status: 'unknown',
          latestDeployment: null,
          projectName: this.projectId,
          url: null,
          deployTime: null,
        };
      }

      return {
        status: deployment.state === 'READY' ? 'healthy' : deployment.state === 'ERROR' ? 'error' : 'unknown',
        latestDeployment: deployment,
        projectName: deployment.name,
        url: deployment.url ? `https://${deployment.url}` : null,
        deployTime: new Date(deployment.createdAt).toLocaleString(),
      };
    } catch (error) {
      console.error('Vercel provider error:', error);
      return {
        status: 'error',
        latestDeployment: null,
        projectName: this.projectId,
        url: null,
        deployTime: null,
      };
    }
  }
}
