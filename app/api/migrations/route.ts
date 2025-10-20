import { createClient } from '@supabase/supabase-js';
import { type NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';
import crypto from 'crypto';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const ADMIN_TOKEN = process.env.INTERNAL_ADMIN_TOKEN;
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// Create Supabase client with service role
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Production-Safe Migration API Route
 *
 * Security:
 * - Requires INTERNAL_ADMIN_TOKEN authentication
 * - Disabled in production by default (use CI/CD instead)
 * - Rate limited and logged
 *
 * Usage:
 *   POST /api/migrations
 *   Headers: { "Authorization": "Bearer <INTERNAL_ADMIN_TOKEN>" }
 *   Body: { "dryRun": true, "version": "01" (optional) }
 */

// Helper: Calculate checksum
function calculateChecksum(content: string): string {
  return crypto.createHash('sha256').update(content).digest('hex');
}

// Helper: Authenticate request
function authenticateRequest(request: NextRequest): boolean {
  if (!ADMIN_TOKEN) {
    console.error('[MIGRATIONS] INTERNAL_ADMIN_TOKEN not configured');
    return false;
  }

  const authHeader = request.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return false;
  }

  const token = authHeader.substring(7);
  return token === ADMIN_TOKEN;
}

// Helper: Get migration files
async function getMigrationFiles() {
  const migrationsDir = path.join(process.cwd(), 'scripts');
  const files = await fs.readdir(migrationsDir);

  return files
    .filter(f => f.endsWith('.sql') && /^\d+_/.test(f))
    .sort()
    .map(filename => ({
      version: filename.split('_')[0],
      name: filename.replace(/^\d+_/, '').replace('.sql', ''),
      filename,
      filepath: path.join(migrationsDir, filename),
    }));
}

// Helper: Execute migration
async function executeMigration(
  migration: { version: string; name: string; filepath: string },
  dryRun: boolean
) {
  const startTime = Date.now();

  try {
    // Read migration file
    const sql = await fs.readFile(migration.filepath, 'utf-8');
    const checksum = calculateChecksum(sql);

    console.log(`[MIGRATIONS] Executing: ${migration.version}_${migration.name}`);

    if (dryRun) {
      console.log(`[MIGRATIONS] DRY RUN - Would execute migration ${migration.version}`);
      return {
        success: true,
        version: migration.version,
        name: migration.name,
        dryRun: true,
        executionTime: 0,
      };
    }

    // Check if migration already applied
    const { data: existing, error: checkError } = await supabase
      .from('schema_migrations')
      .select('status, checksum')
      .eq('version', migration.version)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      // PGRST116 = not found, which is fine
      throw checkError;
    }

    if (existing && existing.status === 'completed') {
      // Validate checksum hasn't changed
      if (existing.checksum !== checksum) {
        throw new Error(
          `Migration ${migration.version} checksum mismatch! ` +
          `File has been modified after being applied. This is unsafe.`
        );
      }

      console.log(`[MIGRATIONS] Migration ${migration.version} already applied`);
      return {
        success: true,
        version: migration.version,
        name: migration.name,
        alreadyApplied: true,
        executionTime: 0,
      };
    }

    // Record migration start
    await supabase.rpc('start_migration', {
      p_version: migration.version,
      p_name: migration.name,
      p_checksum: checksum,
      p_executed_by: 'api_route',
    });

    // Execute SQL
    const { error: execError } = await supabase.rpc('exec_sql', {
      sql_string: sql,
    });

    if (execError) {
      throw execError;
    }

    const executionTime = Date.now() - startTime;

    // Record success
    await supabase.rpc('complete_migration', {
      p_version: migration.version,
      p_execution_time_ms: executionTime,
    });

    console.log(`[MIGRATIONS] Completed ${migration.version} in ${executionTime}ms`);

    return {
      success: true,
      version: migration.version,
      name: migration.name,
      executionTime,
    };

  } catch (error: any) {
    const executionTime = Date.now() - startTime;

    console.error(`[MIGRATIONS] Failed ${migration.version}:`, error.message);

    // Record failure
    try {
      await supabase.rpc('fail_migration', {
        p_version: migration.version,
        p_error_message: error.message,
        p_execution_time_ms: executionTime,
      });
    } catch (recordError) {
      console.error('[MIGRATIONS] Failed to record error:', recordError);
    }

    throw error;
  }
}

export async function POST(request: NextRequest) {
  try {
    // SECURITY: Disabled in production (use CI/CD instead)
    if (IS_PRODUCTION) {
      return NextResponse.json(
        {
          success: false,
          error: 'Migration endpoint disabled in production. Use GitHub Actions workflows instead.',
          hint: 'Push to staging branch or create version tag for production',
        },
        { status: 403 }
      );
    }

    // SECURITY: Require authentication
    if (!authenticateRequest(request)) {
      console.warn('[MIGRATIONS] Unauthorized access attempt');
      return NextResponse.json(
        { success: false, error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Parse request body
    const body = await request.json();
    const dryRun = body.dryRun === true;
    const specificVersion = body.version;

    console.log('[MIGRATIONS] Starting migration run', {
      dryRun,
      specificVersion,
      environment: process.env.NODE_ENV,
    });

    // Get all migration files
    const migrations = await getMigrationFiles();
    console.log(`[MIGRATIONS] Found ${migrations.length} migration files`);

    // Ensure tracking migration runs first
    const trackingMigration = migrations.find(m =>
      m.filename.includes('migration_state_tracking')
    );

    if (trackingMigration) {
      const { data: trackingStatus } = await supabase
        .from('schema_migrations')
        .select('status')
        .eq('version', trackingMigration.version)
        .single();

      if (!trackingStatus || trackingStatus.status !== 'completed') {
        console.log('[MIGRATIONS] Initializing migration tracking...');
        await executeMigration(trackingMigration, dryRun);
      }
    }

    // Filter migrations to run
    let migrationsToRun = migrations.filter(m =>
      !m.filename.includes('migration_state_tracking')
    );

    if (specificVersion) {
      migrationsToRun = migrationsToRun.filter(m => m.version === specificVersion);
      if (migrationsToRun.length === 0) {
        return NextResponse.json(
          {
            success: false,
            error: `Migration version ${specificVersion} not found`,
          },
          { status: 404 }
        );
      }
    }

    // Execute migrations
    const results = [];
    let failedCount = 0;

    for (const migration of migrationsToRun) {
      try {
        const result = await executeMigration(migration, dryRun);
        results.push(result);
      } catch (error: any) {
        failedCount++;
        results.push({
          success: false,
          version: migration.version,
          name: migration.name,
          error: error.message,
        });
        // Stop on first failure
        break;
      }
    }

    // Get final status
    const { data: finalStatus } = await supabase.rpc('get_migration_status');

    const response = {
      success: failedCount === 0,
      dryRun,
      applied: results.filter(r => r.success && !r.alreadyApplied).length,
      alreadyApplied: results.filter(r => r.alreadyApplied).length,
      failed: failedCount,
      results,
      status: finalStatus?.[0] || null,
    };

    console.log('[MIGRATIONS] Run complete', {
      applied: response.applied,
      failed: response.failed,
    });

    return NextResponse.json(response);

  } catch (error: any) {
    console.error('[MIGRATIONS] Fatal error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message,
      },
      { status: 500 }
    );
  }
}

// GET endpoint for status check
export async function GET(request: NextRequest) {
  try {
    // SECURITY: Require authentication even for status
    if (!authenticateRequest(request)) {
      return NextResponse.json(
        { success: false, error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get migration status
    const { data: status, error } = await supabase.rpc('get_migration_status');

    if (error) {
      throw error;
    }

    // Get recent migration history
    const { data: history } = await supabase
      .from('migration_history')
      .select('*')
      .order('executed_at', { ascending: false })
      .limit(10);

    return NextResponse.json({
      success: true,
      status: status?.[0] || null,
      recentHistory: history || [],
      environment: process.env.NODE_ENV,
    });

  } catch (error: any) {
    console.error('[MIGRATIONS] Status check failed:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message,
      },
      { status: 500 }
    );
  }
}
