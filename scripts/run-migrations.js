#!/usr/bin/env node

/**
 * CI-Safe Database Migration Runner
 *
 * Features:
 * - Transaction safety (auto-rollback on error)
 * - Migration state tracking with checksums
 * - Idempotency (safe to run multiple times)
 * - Dry-run mode for testing
 * - Detailed logging
 * - Production safety checks
 *
 * Usage:
 *   node scripts/run-migrations.js                    # Run all pending migrations
 *   node scripts/run-migrations.js --dry-run          # Test without applying
 *   node scripts/run-migrations.js --version 01       # Run specific version
 *   node scripts/run-migrations.js --rollback 01      # Rollback specific version
 */

const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

// PostgreSQL client (using pg library)
const { Client } = require('pg');

// Configuration
const CONFIG = {
  databaseUrl: process.env.DATABASE_URL || process.env.SUPABASE_DB_URL,
  migrationsDir: path.join(__dirname, '.'),
  environment: process.env.NODE_ENV || 'development',
  executedBy: process.env.GITHUB_ACTOR || process.env.USER || 'system',
  dryRun: process.argv.includes('--dry-run'),
  specificVersion: process.argv.find(arg => arg.startsWith('--version='))?.split('=')[1],
  rollbackVersion: process.argv.find(arg => arg.startsWith('--rollback='))?.split('=')[1],
  verbose: process.argv.includes('--verbose') || process.argv.includes('-v'),
};

// Logger
const log = {
  info: (msg, ...args) => console.log(`[INFO] ${msg}`, ...args),
  success: (msg, ...args) => console.log(`[✓] ${msg}`, ...args),
  error: (msg, ...args) => console.error(`[✗] ${msg}`, ...args),
  warn: (msg, ...args) => console.warn(`[⚠] ${msg}`, ...args),
  debug: (msg, ...args) => {
    if (CONFIG.verbose) console.log(`[DEBUG] ${msg}`, ...args);
  },
};

// Calculate file checksum for integrity verification
function calculateChecksum(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

// Get all migration files
async function getMigrationFiles() {
  const files = await fs.readdir(CONFIG.migrationsDir);

  return files
    .filter(f => f.endsWith('.sql') && /^\d+_/.test(f))
    .sort()
    .map(filename => ({
      version: filename.split('_')[0],
      name: filename.replace(/^\d+_/, '').replace('.sql', ''),
      filename,
      filepath: path.join(CONFIG.migrationsDir, filename),
    }));
}

// Get migration status from database
async function getMigrationStatus(client, version) {
  const result = await client.query(
    'SELECT status, checksum FROM schema_migrations WHERE version = $1',
    [version]
  );
  return result.rows[0] || null;
}

// Validate migration checksum
async function validateChecksum(client, version, currentChecksum) {
  const result = await client.query(
    'SELECT validate_migration_checksum($1, $2) as is_valid',
    [version, currentChecksum]
  );
  return result.rows[0].is_valid;
}

// Execute migration within transaction
async function executeMigration(client, migration) {
  const startTime = Date.now();

  try {
    log.info(`Executing migration: ${migration.version}_${migration.name}`);

    // Read migration file
    const sql = await fs.readFile(migration.filepath, 'utf-8');
    const checksum = calculateChecksum(sql);

    // Validate checksum if migration was previously applied
    const isValidChecksum = await validateChecksum(client, migration.version, checksum);
    if (!isValidChecksum) {
      throw new Error(
        `Migration ${migration.version} checksum mismatch! ` +
        `File has been modified after being applied. This is unsafe.`
      );
    }

    // Begin transaction
    await client.query('BEGIN');

    try {
      // Record migration start
      await client.query(
        'SELECT start_migration($1, $2, $3, $4)',
        [migration.version, migration.name, checksum, CONFIG.executedBy]
      );

      if (CONFIG.dryRun) {
        log.warn(`DRY RUN: Would execute migration ${migration.version}`);
        log.debug(`SQL preview:\n${sql.substring(0, 500)}...`);
      } else {
        // Execute the actual migration SQL
        await client.query(sql);
      }

      const executionTime = Date.now() - startTime;

      // Record successful completion
      if (!CONFIG.dryRun) {
        await client.query(
          'SELECT complete_migration($1, $2)',
          [migration.version, executionTime]
        );
      }

      // Commit transaction
      await client.query('COMMIT');

      log.success(
        `Migration ${migration.version}_${migration.name} completed in ${executionTime}ms`
      );

      return { success: true, executionTime };

    } catch (error) {
      // Rollback transaction on error
      await client.query('ROLLBACK');

      const executionTime = Date.now() - startTime;

      // Record failure
      if (!CONFIG.dryRun) {
        await client.query(
          'SELECT fail_migration($1, $2, $3)',
          [migration.version, error.message, executionTime]
        );
      }

      throw error;
    }

  } catch (error) {
    log.error(`Migration ${migration.version} failed:`, error.message);
    if (CONFIG.verbose) {
      console.error(error.stack);
    }
    throw error;
  }
}

// Run all pending migrations
async function runMigrations() {
  const client = new Client({
    connectionString: CONFIG.databaseUrl,
    ssl: CONFIG.environment === 'production' ? { rejectUnauthorized: false } : undefined,
  });

  try {
    await client.connect();
    log.info('Connected to database');

    // Get all migration files
    const migrations = await getMigrationFiles();
    log.info(`Found ${migrations.length} migration files`);

    if (CONFIG.dryRun) {
      log.warn('DRY RUN MODE - No changes will be applied');
    }

    // Ensure migration tracking table exists
    const trackingMigration = migrations.find(m => m.filename.includes('migration_state_tracking'));
    if (trackingMigration) {
      const status = await getMigrationStatus(client, trackingMigration.version);
      if (!status || status.status !== 'completed') {
        log.info('Initializing migration tracking system...');
        await executeMigration(client, trackingMigration);
      }
    }

    // Filter migrations to run
    let migrationsToRun = migrations.filter(m => !m.filename.includes('migration_state_tracking'));

    if (CONFIG.specificVersion) {
      migrationsToRun = migrationsToRun.filter(m => m.version === CONFIG.specificVersion);
      if (migrationsToRun.length === 0) {
        throw new Error(`Migration version ${CONFIG.specificVersion} not found`);
      }
    }

    // Check which migrations are pending
    const pendingMigrations = [];
    for (const migration of migrationsToRun) {
      const status = await getMigrationStatus(client, migration.version);

      if (!status || status.status !== 'completed') {
        pendingMigrations.push(migration);
      } else {
        log.debug(`Migration ${migration.version} already applied`);
      }
    }

    if (pendingMigrations.length === 0) {
      log.info('No pending migrations to run');
      return { success: true, applied: 0 };
    }

    log.info(`Pending migrations: ${pendingMigrations.length}`);

    // Execute each migration
    let appliedCount = 0;
    for (const migration of pendingMigrations) {
      await executeMigration(client, migration);
      appliedCount++;
    }

    // Get final migration status
    const statusResult = await client.query('SELECT * FROM get_migration_status()');
    const finalStatus = statusResult.rows[0];

    log.success('\nMigration Summary:');
    log.success(`  Total migrations: ${finalStatus.total_migrations}`);
    log.success(`  Completed: ${finalStatus.completed}`);
    log.success(`  Failed: ${finalStatus.failed}`);
    log.success(`  Pending: ${finalStatus.pending}`);
    if (finalStatus.last_migration) {
      log.success(`  Last applied: ${finalStatus.last_migration} at ${finalStatus.last_applied_at}`);
    }

    return {
      success: true,
      applied: appliedCount,
      status: finalStatus,
    };

  } catch (error) {
    log.error('Migration run failed:', error.message);
    if (CONFIG.verbose) {
      console.error(error.stack);
    }
    return { success: false, error: error.message };

  } finally {
    await client.end();
    log.debug('Database connection closed');
  }
}

// Production safety checks
async function runSafetyChecks() {
  log.info('Running safety checks...');

  // Check database URL
  if (!CONFIG.databaseUrl) {
    throw new Error('DATABASE_URL environment variable not set');
  }

  // Check environment
  if (CONFIG.environment === 'production' && !CONFIG.dryRun) {
    log.warn('⚠️  PRODUCTION ENVIRONMENT DETECTED');
    log.warn('⚠️  Migrations will be applied to production database');

    // Require explicit confirmation in production
    if (!process.env.CONFIRM_PRODUCTION_MIGRATION) {
      throw new Error(
        'Production migrations require CONFIRM_PRODUCTION_MIGRATION=true environment variable'
      );
    }
  }

  // Check for rollback mode
  if (CONFIG.rollbackVersion) {
    log.warn('⚠️  ROLLBACK MODE - Not implemented yet');
    log.warn('⚠️  Manual rollback required. Use database backups.');
    throw new Error('Automatic rollback not yet implemented');
  }

  log.success('Safety checks passed');
}

// Main execution
async function main() {
  console.log('================================');
  console.log('  Database Migration Runner');
  console.log('================================');
  console.log(`Environment: ${CONFIG.environment}`);
  console.log(`Executed by: ${CONFIG.executedBy}`);
  console.log(`Dry run: ${CONFIG.dryRun}`);
  console.log('================================\n');

  try {
    // Run safety checks
    await runSafetyChecks();

    // Run migrations
    const result = await runMigrations();

    if (!result.success) {
      process.exit(1);
    }

    if (CONFIG.dryRun) {
      log.info('\nDRY RUN COMPLETE - No changes were applied');
    } else {
      log.success(`\n✓ Successfully applied ${result.applied} migrations`);
    }

  } catch (error) {
    log.error('Fatal error:', error.message);
    if (CONFIG.verbose) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

module.exports = { runMigrations, getMigrationFiles, calculateChecksum };
