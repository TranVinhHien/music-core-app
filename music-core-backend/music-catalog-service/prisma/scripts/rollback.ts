import * as fs from 'fs';
import * as path from 'path';
import { Client } from 'pg';
import { execSync } from 'child_process';
import * as dotenv from 'dotenv';

dotenv.config();

async function rollback() {
  const migrationsDir = path.join(__dirname, '..', 'migrations');
  if (!fs.existsSync(migrationsDir)) {
    console.error('No migrations directory found at', migrationsDir);
    process.exit(1);
  }

  // Get all migration directories sorted in ascending order
  const migrationDirs = fs
    .readdirSync(migrationsDir, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory() && dirent.name.match(/^\d{14}_/))
    .map((dirent) => dirent.name)
    .sort();

  if (migrationDirs.length === 0) {
    console.log('No migration versions found to rollback.');
    return;
  }

  // Pick the latest migration
  const latestMigration = migrationDirs[migrationDirs.length - 1];
  const downSqlPath = path.join(migrationsDir, latestMigration, 'down.sql');

  if (!fs.existsSync(downSqlPath)) {
    console.error(`Cannot rollback: No down.sql found in ${latestMigration}`);
    process.exit(1);
  }

  const downSql = fs.readFileSync(downSqlPath, 'utf-8');
  console.log(`\nRolling back migration: ${latestMigration}...`);

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('DATABASE_URL is not set in environment or .env');
    process.exit(1);
  }

  const client = new Client({ connectionString });
  await client.connect();

  try {
    await client.query('BEGIN');
    await client.query(downSql);
    await client.query('COMMIT');
    console.log(`Executed down.sql successfully.`);

    // Update Prisma migration status table
    try {
      console.log(`Resolving Prisma state with: npx prisma migrate resolve --rolled-back "${latestMigration}"`);
      execSync(`npx prisma migrate resolve --rolled-back "${latestMigration}"`, {
        stdio: 'inherit',
      });
    } catch (resolveErr) {
      console.warn(
        `Warning: Prisma migrate resolve was not able to update _prisma_migrations table automatically. Check if database has _prisma_migrations.`,
      );
    }

    console.log(`Rollback completed for version: ${latestMigration}\n`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error executing down.sql:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

rollback().catch((err) => {
  console.error('Unexpected rollback error:', err);
  process.exit(1);
});
