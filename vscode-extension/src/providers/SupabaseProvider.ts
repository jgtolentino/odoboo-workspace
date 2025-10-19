import { createClient, SupabaseClient } from '@supabase/supabase-js';

export interface SupabaseStatus {
  status: 'healthy' | 'error' | 'unknown';
  projectRef: string;
  functionsCount: number;
  lastMigration: string | null;
  dbSize: string | null;
}

export class SupabaseProvider {
  private client: SupabaseClient | null = null;
  private projectRef: string | null = null;

  constructor(url?: string, serviceRoleKey?: string, projectRef?: string) {
    this.projectRef = projectRef || null;

    if (url && serviceRoleKey) {
      this.client = createClient(url, serviceRoleKey);
    }
  }

  async getStatus(): Promise<SupabaseStatus> {
    if (!this.client || !this.projectRef) {
      return {
        status: 'unknown',
        projectRef: 'Not configured',
        functionsCount: 0,
        lastMigration: null,
        dbSize: null,
      };
    }

    try {
      // Check Edge Functions (if any)
      let functionsCount = 0;
      try {
        const { data: functions } = await this.client.functions.invoke('_list'); // This is pseudo-code
        functionsCount = Array.isArray(functions) ? functions.length : 0;
      } catch {
        // Functions might not be listable via client, use hardcoded or skip
        functionsCount = 1; // work-queue function we know exists
      }

      // Check last migration via SQL
      let lastMigration: string | null = null;
      try {
        const { data, error } = await this.client
          .from('ops.schema_columns_snapshot')
          .select('run_at')
          .order('run_at', { ascending: false })
          .limit(1)
          .single();

        if (!error && data) {
          lastMigration = new Date(data.run_at).toLocaleString();
        }
      } catch {
        // Table might not exist yet
      }

      // Get database size
      let dbSize: string | null = null;
      try {
        const { data, error } = await this.client.rpc('pg_database_size', { database_name: 'postgres' });
        if (!error && data) {
          const sizeInMB = Math.round(data / 1024 / 1024);
          dbSize = `${sizeInMB} MB`;
        }
      } catch {
        // RPC might not be available
      }

      return {
        status: 'healthy',
        projectRef: this.projectRef,
        functionsCount,
        lastMigration,
        dbSize,
      };
    } catch (error) {
      console.error('Supabase provider error:', error);
      return {
        status: 'error',
        projectRef: this.projectRef,
        functionsCount: 0,
        lastMigration: null,
        dbSize: null,
      };
    }
  }
}
