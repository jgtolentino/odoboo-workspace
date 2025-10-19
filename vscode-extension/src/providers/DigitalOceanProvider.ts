export interface DODeployment {
  id: string;
  phase: 'PENDING_BUILD' | 'BUILDING' | 'PENDING_DEPLOY' | 'DEPLOYING' | 'ACTIVE' | 'SUPERSEDED' | 'ERROR' | 'CANCELED';
  created_at: string;
  updated_at: string;
  cause: string;
}

export interface DOStatus {
  status: 'healthy' | 'error' | 'unknown';
  latestDeployment: DODeployment | null;
  appName: string;
  region: string;
  liveUrl: string | null;
  deployTime: string | null;
}

export class DigitalOceanProvider {
  private token: string | null = null;
  private appId: string | null = null;

  constructor(token?: string, appId?: string) {
    this.token = token || process.env.DO_ACCESS_TOKEN || null;
    this.appId = appId || null;
  }

  async getStatus(): Promise<DOStatus> {
    if (!this.token || !this.appId) {
      return {
        status: 'unknown',
        latestDeployment: null,
        appName: 'Not configured',
        region: 'unknown',
        liveUrl: null,
        deployTime: null,
      };
    }

    try {
      // Get app info
      const appUrl = `https://api.digitalocean.com/v2/apps/${this.appId}`;
      const appResponse = await fetch(appUrl, {
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!appResponse.ok) {
        return {
          status: 'error',
          latestDeployment: null,
          appName: this.appId,
          region: 'unknown',
          liveUrl: null,
          deployTime: null,
        };
      }

      const appData = (await appResponse.json()) as {
        app: {
          spec?: { name?: string };
          region?: { slug?: string };
          live_url?: string;
        };
      };
      const app = appData.app;

      // Get latest deployment
      const deploymentsUrl = `https://api.digitalocean.com/v2/apps/${this.appId}/deployments`;
      const deployResponse = await fetch(deploymentsUrl, {
        headers: {
          Authorization: `Bearer ${this.token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!deployResponse.ok) {
        return {
          status: 'error',
          latestDeployment: null,
          appName: app.spec?.name || this.appId,
          region: app.region?.slug || 'unknown',
          liveUrl: app.live_url || null,
          deployTime: null,
        };
      }

      const deployData = (await deployResponse.json()) as { deployments?: DODeployment[] };
      const deployment = deployData.deployments?.[0];

      if (!deployment) {
        return {
          status: 'unknown',
          latestDeployment: null,
          appName: app.spec?.name || this.appId,
          region: app.region?.slug || 'unknown',
          liveUrl: app.live_url || null,
          deployTime: null,
        };
      }

      const doDeployment: DODeployment = {
        id: deployment.id,
        phase: deployment.phase,
        created_at: deployment.created_at,
        updated_at: deployment.updated_at,
        cause: deployment.cause || 'Manual',
      };

      let status: 'healthy' | 'error' | 'unknown' = 'unknown';
      if (deployment.phase === 'ACTIVE') {
        status = 'healthy';
      } else if (deployment.phase === 'ERROR' || deployment.phase === 'CANCELED') {
        status = 'error';
      } else if (deployment.phase === 'BUILDING' || deployment.phase === 'DEPLOYING') {
        status = 'healthy'; // In progress is considered healthy
      }

      return {
        status,
        latestDeployment: doDeployment,
        appName: app.spec?.name || this.appId,
        region: app.region?.slug || 'unknown',
        liveUrl: app.live_url || null,
        deployTime: new Date(deployment.updated_at).toLocaleString(),
      };
    } catch (error) {
      console.error('DigitalOcean provider error:', error);
      return {
        status: 'error',
        latestDeployment: null,
        appName: this.appId,
        region: 'unknown',
        liveUrl: null,
        deployTime: null,
      };
    }
  }
}
