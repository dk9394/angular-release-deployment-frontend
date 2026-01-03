#!/usr/bin/env node

/**
 * Cross-Platform Deployment Script for Angular App
 *
 * This is a Node.js version of deploy.sh that works on Windows, macOS, and Linux.
 *
 * Usage:
 *   node deploy.mjs <environment>
 *   npm run deploy:dev:node
 *   npm run deploy:prod:node
 *
 * Environments: dev, qa, staging, prod
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ANSI color codes (works on Windows 10+, macOS, Linux)
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

// Logging helpers
const log = {
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.yellow}${msg}${colors.reset}`),
  error: (msg) => console.error(`${colors.red}❌ ${msg}${colors.reset}`),
  header: (msg) => console.log(`${colors.green}${msg}${colors.reset}`),
  cyan: (msg) => console.log(`${colors.cyan}${msg}${colors.reset}`)
};

// Get environment from command line arguments
const environment = process.argv[2];
const validEnvironments = ['dev', 'qa', 'staging', 'prod'];

// ─────────────────────────────────────────────────────────────
// Validation
// ─────────────────────────────────────────────────────────────

if (!environment) {
  log.error('No environment specified');
  console.log('');
  console.log('Usage: node deploy.mjs [dev|qa|staging|prod]');
  console.log('');
  console.log('Examples:');
  console.log('  node deploy.mjs dev       # Deploy to development');
  console.log('  node deploy.mjs qa        # Deploy to QA');
  console.log('  node deploy.mjs staging   # Deploy to staging');
  console.log('  node deploy.mjs prod      # Deploy to production');
  console.log('');
  console.log('Or use npm scripts:');
  console.log('  npm run deploy:dev:node');
  console.log('  npm run deploy:prod:node');
  process.exit(1);
}

if (!validEnvironments.includes(environment)) {
  log.error(`Invalid environment: '${environment}'`);
  console.log(`Must be one of: ${validEnvironments.join(', ')}`);
  process.exit(1);
}

// ─────────────────────────────────────────────────────────────
// Load Environment Variables
// ─────────────────────────────────────────────────────────────

const envFilePath = path.join(__dirname, '.env.aws');

if (!fs.existsSync(envFilePath)) {
  log.error('.env.aws file not found!');
  console.log('Please ensure .env.aws exists with UNIQUE_ID variable');
  process.exit(1);
}

// Parse .env.aws file
const envFileContent = fs.readFileSync(envFilePath, 'utf-8');
const envVars = envFileContent
  .split('\n')
  .filter(line => line.trim() && !line.startsWith('#'))
  .reduce((acc, line) => {
    const [key, value] = line.split('=');
    if (key && value) {
      acc[key.trim()] = value.trim();
    }
    return acc;
  }, {});

const UNIQUE_ID = envVars.UNIQUE_ID;
const CLOUDFRONT_DISTRIBUTION_ID = envVars.CLOUDFRONT_DISTRIBUTION_ID;
const CLOUDFRONT_DOMAIN = envVars.CLOUDFRONT_DOMAIN;

if (!UNIQUE_ID) {
  log.error('UNIQUE_ID not found in .env.aws');
  process.exit(1);
}

// ─────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────

const bucketName = `angular-deploy-${environment}-${UNIQUE_ID}`;

// Map 'prod' to 'production' for the config file
const configFile = environment === 'prod'
  ? 'environment.production.json'
  : `environment.${environment}.json`;

// ─────────────────────────────────────────────────────────────
// Display Deployment Info
// ─────────────────────────────────────────────────────────────

console.log('');
log.header('========================================');
log.header('  AWS S3 Deployment Script');
log.header('========================================');
console.log('');
console.log(`Environment:  ${environment}`);
console.log(`Bucket:       ${bucketName}`);
console.log(`Config:       ${configFile}`);
console.log('');

// ─────────────────────────────────────────────────────────────
// Deployment Steps
// ─────────────────────────────────────────────────────────────

try {
  // Step 1: Build Angular application
  log.info('[1/4] Building Angular application...');
  execSync('npm run build -- --configuration=production', {
    stdio: 'inherit',
    env: { ...process.env }
  });
  log.success('Build completed successfully');
  console.log('');

  // Step 2: Swap environment configuration
  log.info('[2/4] Swapping environment configuration...');

  const sourceConfig = path.join(__dirname, 'src', 'assets', 'config', configFile);
  const targetConfig = path.join(
    __dirname,
    'dist',
    'angular-release-deployment-frontend',
    'browser',
    'assets',
    'config',
    'environment.json'
  );

  if (!fs.existsSync(sourceConfig)) {
    throw new Error(`Config file not found: ${sourceConfig}`);
  }

  fs.copyFileSync(sourceConfig, targetConfig);
  log.success(`Configuration swapped to ${environment}`);
  console.log('');

  // Step 3: Deploy to S3
  log.info(`[3/4] Deploying to S3 bucket: ${bucketName}`);
  console.log('');

  const distPath = path.join(
    __dirname,
    'dist',
    'angular-release-deployment-frontend',
    'browser'
  );

  // Use cross-platform path handling for aws s3 sync
  const s3SyncCommand = `aws s3 sync "${distPath}" s3://${bucketName} --delete`;

  execSync(s3SyncCommand, {
    stdio: 'inherit'
  });

  console.log('');
  log.success('Files uploaded to S3');
  console.log('');

  // Step 4: Invalidate CloudFront cache (production only)
  if (environment === 'prod') {
    log.info('[4/5] Invalidating CloudFront cache...');
    console.log('');

    if (!CLOUDFRONT_DISTRIBUTION_ID) {
      log.info('⚠️  CloudFront distribution ID not found in .env.aws');
      log.info('⚠️  Skipping cache invalidation');
      console.log('');
    } else {
      try {
        execSync(
          `aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DISTRIBUTION_ID} --paths "/*"`,
          { stdio: 'pipe' } // Hide verbose output
        );
        log.success('CloudFront cache invalidated');
        log.success('Fresh content will be available within 1-2 minutes');
        console.log('');
      } catch (error) {
        log.info('⚠️  CloudFront invalidation failed (not critical)');
        console.log('');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Success Summary
  // ─────────────────────────────────────────────────────────────

  const stepLabel = environment === 'prod' ? '[5/5]' : '[4/4]';
  log.info(`${stepLabel} Deployment complete!`);
  console.log('');

  log.header('========================================');
  log.header('  Deployment Successful! 🚀');
  log.header('========================================');
  console.log('');
  console.log(`Environment:  ${environment}`);
  console.log(`Bucket:       ${bucketName}`);
  console.log('');

  if (environment === 'prod') {
    console.log('Your app is live at:');
    log.success(`https://${CLOUDFRONT_DOMAIN} (CloudFront - Recommended)`);
    log.cyan(`http://${bucketName}.s3-website-us-east-1.amazonaws.com (S3 Direct)`);
  } else {
    console.log('Your app is live at:');
    log.success(`http://${bucketName}.s3-website-us-east-1.amazonaws.com`);
  }

  console.log('');

} catch (error) {
  // ─────────────────────────────────────────────────────────────
  // Error Handling
  // ─────────────────────────────────────────────────────────────

  console.log('');
  log.error('Deployment failed!');

  if (error.message) {
    console.error(error.message);
  }

  if (error.stderr) {
    console.error(error.stderr.toString());
  }

  console.log('');
  process.exit(1);
}
