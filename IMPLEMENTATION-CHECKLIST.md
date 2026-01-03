# Angular Release & Deployment - Implementation Checklist

This document tracks all completed steps in sequential order. Use this as a self-contained reference when setting up similar projects from scratch.

**Legend:**
- Steps marked with `*` are **mandatory** for core functionality
- Steps without `*` are optional/reference documentation

---

## Phase 1: Frontend Project Foundation

### Step 1*: Create Angular Project with Nx
- ✅ Created Nx workspace with Angular
- ✅ Configured npm as package manager
- ✅ Set up project structure

**Commands:**
```bash
npx create-nx-workspace@latest angular-release-deployment-frontend \
  --preset=angular-monorepo \
  --packageManager=npm \
  --nxCloud=skip

cd angular-release-deployment-frontend
```

**Outcome:** Base Angular project structure created

---

### Step 2*: Configure TypeScript Strict Mode
- ✅ Enabled strict mode in `tsconfig.json`
- ✅ Configured strict type checking options

**Files Modified:** `tsconfig.json`

**Changes to make:**
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true
  }
}
```

**Outcome:** Maximum type safety enabled

---

### Step 3*: Set Up ESLint
- ✅ Configured ESLint with Angular-specific rules
- ✅ Added TypeScript ESLint parser
- ✅ Configured production-grade linting rules

**Files Created:** `eslint.config.js`

**Complete file content:**
```javascript
// @ts-check
const eslint = require("@eslint/js");
const { defineConfig } = require("eslint/config");
const tseslint = require("typescript-eslint");
const angular = require("angular-eslint");
const prettierConfig = require("eslint-config-prettier");

module.exports = defineConfig([
  {
    files: ["**/*.ts"],
    extends: [
      eslint.configs.recommended,
      tseslint.configs.recommended,
      tseslint.configs.stylistic,
      angular.configs.tsRecommended,
      prettierConfig,
    ],
    processor: angular.processInlineTemplates,
    rules: {
      "@angular-eslint/directive-selector": [
        "error",
        {
          type: "attribute",
          prefix: "app",
          style: "camelCase",
        },
      ],
      "@angular-eslint/component-selector": [
        "error",
        {
          type: "element",
          prefix: "app",
          style: "kebab-case",
        },
      ],
      // Disable standalone enforcement (we're using module-based architecture intentionally)
      "@angular-eslint/prefer-standalone": "off",
      // Allow constructor injection (traditional Angular pattern)
      "@angular-eslint/prefer-inject": "off",
      // Production-grade rules
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-debugger": "error",
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-unused-vars": ["error", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_"
      }],
    },
  },
  {
    files: ["**/*.html"],
    extends: [
      angular.configs.templateRecommended,
      angular.configs.templateAccessibility,
    ],
    rules: {},
  }
]);
```

**Commands:**
```bash
npm run lint
```

**Outcome:** Code quality enforcement configured

---

### Step 4*: Set Up Prettier
- ✅ Configured Prettier for consistent code formatting
- ✅ Integrated with ESLint
- ✅ Configured ignore patterns

**Commands:**
```bash
npm install --save-dev prettier eslint-config-prettier
```

**Files Created:** `.prettierrc`

**Complete file content:**
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "bracketSpacing": true,
  "overrides": [
    {
      "files": "*.html",
      "options": {
        "parser": "angular"
      }
    }
  ]
}
```

**Files Created:** `.prettierignore`

**Complete file content:**
```
# Build outputs
dist
node_modules
.angular

# Logs
*.log

# Lock files
package-lock.json
yarn.lock
pnpm-lock.yaml

# Environment files
.env*

# Coverage
coverage
```

**Commands:**
```bash
npm run format
```

**Outcome:** Automated code formatting configured

---

### Step 5*: Set Up Git Hooks with Husky
- ✅ Initialized Husky for Git hooks
- ✅ Configured pre-commit hook with lint-staged
- ✅ Configured commit-msg hook with commitlint

**Commands:**
```bash
# Install packages
npm install --save-dev husky lint-staged @commitlint/cli @commitlint/config-conventional

# Initialize Husky
npx husky init

# Create pre-commit hook
cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
EOF

# Create commit-msg hook
cat > .husky/commit-msg << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no -- commitlint --edit $1
EOF

# Make hooks executable
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg
```

**Files Created:** `.lintstagedrc.json`

**Complete file content:**
```json
{
  "*.{ts,html}": ["prettier --write", "eslint --fix"],
  "*.{scss,css,json}": ["prettier --write"]
}
```

**Files Created:** `commitlint.config.js`

**Complete file content:**
```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Code style (formatting, semicolons, etc)
        'refactor', // Code refactoring (no feature/fix)
        'perf',     // Performance improvement
        'test',     // Adding/updating tests
        'build',    // Build system or dependencies
        'ci',       // CI/CD configuration
        'chore',    // Other changes (no production code)
        'revert',   // Revert previous commit
      ],
    ],
  },
};
```

**Outcome:** Automated quality checks before commits

---

## Phase 2: Frontend Runtime Environment Configuration

### Step 6*: Create Environment Configuration Structure
- ✅ Created `src/assets/config/` directory
- ✅ Created environment-specific JSON files

**Commands:**
```bash
# Create config directory
mkdir -p src/assets/config
```

**Files Created:** `src/assets/config/environment.dev.json`

**Complete file content:**
```json
{
  "name": "development",
  "production": false,
  "apiUrl": "http://localhost:3000/api",
  "authUrl": "http://localhost:3000/auth",
  "features": {
    "enableAnalytics": false,
    "enableLogging": true,
    "enableDebugMode": true
  }
}
```

**Files Created:** `src/assets/config/environment.qa.json`

**Complete file content:**
```json
{
  "name": "qa",
  "production": false,
  "apiUrl": "https://api-qa.yourapp.com/api",
  "authUrl": "https://api-qa.yourapp.com/auth",
  "features": {
    "enableAnalytics": false,
    "enableLogging": true,
    "enableDebugMode": false
  }
}
```

**Files Created:** `src/assets/config/environment.staging.json`

**Complete file content:**
```json
{
  "name": "staging",
  "production": false,
  "apiUrl": "https://api-staging.yourapp.com/api",
  "authUrl": "https://api-staging.yourapp.com/auth",
  "features": {
    "enableAnalytics": true,
    "enableLogging": true,
    "enableDebugMode": false
  }
}
```

**Files Created:** `src/assets/config/environment.production.json`

**Complete file content:**
```json
{
  "name": "production",
  "production": true,
  "apiUrl": "https://api.yourapp.com/api",
  "authUrl": "https://api.yourapp.com/auth",
  "features": {
    "enableAnalytics": true,
    "enableLogging": false,
    "enableDebugMode": false
  }
}
```

**Files Created:** `src/assets/config/environment.json` (default - copy from dev)

**Complete file content:**
```json
{
  "name": "development",
  "production": false,
  "apiUrl": "http://localhost:3000/api",
  "authUrl": "http://localhost:3000/auth",
  "features": {
    "enableAnalytics": false,
    "enableLogging": true,
    "enableDebugMode": true
  }
}
```

**Outcome:** Runtime environment configuration prepared

---

### Step 7*: Create ConfigService for Runtime Loading
- ✅ Created TypeScript interface for environment config
- ✅ Created `ConfigService` in `src/app/core/services/`
- ✅ Implemented HTTP-based config loading

**Commands:**
```bash
# Create directory structure
mkdir -p src/app/core/services
mkdir -p src/app/core/models
```

**Files Created:** `src/app/core/models/environment.model.ts`

**Complete file content:**
```typescript
export interface EnvironmentConfig {
  name: string;
  production: boolean;
  apiUrl: string;
  authUrl: string;
  features: {
    enableAnalytics: boolean;
    enableLogging: boolean;
    enableDebugMode: boolean;
  };
}
```

**Files Created:** `src/app/core/services/config.service.ts`

**Complete file content:**
```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { EnvironmentConfig } from '../models/environment.model';
import { firstValueFrom } from 'rxjs';

/**
 * ConfigService
 * Loads and provides runtime environment configuration
 * Loaded via APP_INITIALIZER before app starts
 */
@Injectable({
  providedIn: 'root',
})
export class ConfigService {
  private config: EnvironmentConfig | null = null;
  private readonly CONFIG_PATH = '/assets/config/environment.json';

  constructor(private http: HttpClient) {}

  /**
   * Load configuration from JSON file
   * Called by APP_INITIALIZER before app bootstrap
   */
  async loadConfig(): Promise<void> {
    try {
      this.config = await firstValueFrom(this.http.get<EnvironmentConfig>(this.CONFIG_PATH));

      // Validate configuration
      this.validateConfig(this.config);

      console.warn(\`[ConfigService] Configuration loaded for environment: \${this.config.name}\`);
    } catch (error) {
      console.error('[ConfigService] Failed to load configuration:', error);
      throw new Error('Failed to load application configuration');
    }
  }

  /**
   * Get current configuration
   * Throws error if config not loaded
   */
  getConfig(): EnvironmentConfig {
    if (!this.config) {
      throw new Error('Configuration not loaded. APP_INITIALIZER may have failed.');
    }
    return this.config;
  }

  /**
   * Get specific config value with type safety
   */
  get apiUrl(): string {
    return this.getConfig().apiUrl;
  }

  get authUrl(): string {
    return this.getConfig().authUrl;
  }

  get isProduction(): boolean {
    return this.getConfig().production;
  }

  get environmentName(): string {
    return this.getConfig().name;
  }

  get features() {
    return this.getConfig().features;
  }

  /**
   * Validate configuration structure
   * Fail fast if required fields missing
   */
  private validateConfig(config: EnvironmentConfig): void {
    const requiredFields: (keyof EnvironmentConfig)[] = [
      'name',
      'production',
      'apiUrl',
      'authUrl',
      'features',
    ];

    for (const field of requiredFields) {
      if (config[field] === undefined || config[field] === null) {
        throw new Error(\`Missing required configuration field: \${field}\`);
      }
    }

    // Validate URLs
    if (!this.isValidUrl(config.apiUrl)) {
      throw new Error(\`Invalid API URL: \${config.apiUrl}\`);
    }

    if (!this.isValidUrl(config.authUrl)) {
      throw new Error(\`Invalid Auth URL: \${config.authUrl}\`);
    }

    console.warn('[ConfigService] Configuration validation passed');
  }

  /**
   * Simple URL validation
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }
}
```

**Outcome:** Runtime configuration loading service created

---

### Step 8*: Configure APP_INITIALIZER for Config Preload
- ✅ Set up APP_INITIALIZER in app.config.ts (or main.ts)
- ✅ Ensured config loads before app bootstrap

**Files Modified:** `src/app/app.config.ts` (or create if doesn't exist)

**Add this to your app configuration providers:**
```typescript
import { ApplicationConfig, APP_INITIALIZER } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { ConfigService } from './core/services/config.service';

export function initializeApp(configService: ConfigService) {
  return () => configService.loadConfig();
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(),
    {
      provide: APP_INITIALIZER,
      useFactory: initializeApp,
      deps: [ConfigService],
      multi: true
    },
    // ... other providers
  ]
};
```

**Alternative (if using main.ts directly):** Add providers to `bootstrapApplication` call

**Outcome:** Config loads before app starts

---

### Step 9*: Update Angular Configuration
- ✅ Configured asset copying for environment files
- ✅ Set up build configurations for all environments

**Files Modified:** `angular.json`

**Find the `"assets"` array in your build configuration and update it:**
```json
{
  "projects": {
    "your-project-name": {
      "architect": {
        "build": {
          "options": {
            "assets": [
              "src/favicon.ico",
              "src/assets",
              {
                "glob": "**/*",
                "input": "src/assets/config",
                "output": "/assets/config"
              }
            ]
          }
        }
      }
    }
  }
}
```

**Outcome:** Build system configured to copy environment files

---

### Step 10*: Test Runtime Configuration
- ✅ Built application with production configuration
- ✅ Verified environment files copied to dist
- ✅ Tested config swapping without rebuild

**Commands:**
```bash
# Build the app
npm run build

# Verify config files copied
ls -la dist/angular-release-deployment-frontend/browser/assets/config/

# Test config swapping (without rebuild)
cp src/assets/config/environment.production.json \
   dist/angular-release-deployment-frontend/browser/assets/config/environment.json

# Serve and test
npx http-server dist/angular-release-deployment-frontend/browser -p 8080
```

**Outcome:** Runtime configuration verified working

---

## Phase 2.5: Backend API Setup

### Step 10B: Create Node.js Express Backend
- ✅ Initialized Node.js project for backend API
- ✅ Set up Express server with CORS
- ✅ Created sample API endpoints

**Commands:**
```bash
mkdir backend-api
cd backend-api
npm init -y
npm install express cors
```

**Files Created:** `backend-api/server.js`

**Complete file content:**
```javascript
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Enable CORS
app.use(cors({
  origin: ['http://localhost:4200', 'https://dev.yourapp.com'],
  credentials: true
}));

app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Sample users endpoint
app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
  ]);
});

app.listen(PORT, () => {
  console.log(\`Backend API running on http://localhost:\${PORT}\`);
});
```

**Commands to run:**
```bash
node server.js
```

**Outcome:** Backend API running on http://localhost:3000

---

## Phase 3: Frontend Git Workflow

### Step 11*: Initialize Git Repository
- ✅ Initialized Git repository
- ✅ Created initial commit
- ✅ Configured `.gitignore`

**Commands:**
```bash
git init
git add .
git commit -m "feat: initial project setup with runtime config and code quality tools"
```

**Outcome:** Git repository initialized

---

### Step 12*: Set Up Git Flow Branching Strategy
- ✅ Created permanent branches: `main`, `staging`, `develop`
- ✅ Pushed all branches to remote
- ✅ Created GitHub repository

**Commands:**
```bash
# Create develop and staging branches
git branch develop
git branch staging

# Create GitHub repository (via GitHub website or gh CLI)
# Then add remote
git remote add origin https://github.com/YOUR_USERNAME/your-repo-name.git

# Push all branches
git push -u origin main
git push -u origin develop
git push -u origin staging
```

**Branch Structure:**
```
main        → Production environment
staging     → Stakeholder demo environment
develop     → Development integration branch
```

**Outcome:** Git Flow branches established

---

### Step 13*: Configure Branch Protection Rules
- ✅ Protected `main` branch (2 approvals required in team environment)
- ✅ Protected `staging` branch (1 approval required in team environment)
- ✅ Protected `develop` branch (0 approvals for solo dev)
- ✅ Enabled PR requirements for all protected branches

**GitHub Settings (via web UI):**

1. Go to: Settings → Branches → Add branch protection rule
2. For `main`:
   - Branch name pattern: `main`
   - ✅ Require pull request before merging
   - ✅ Require approvals: 2
   - ✅ Require conversation resolution
   - ✅ Require linear history
   - ✅ Do not allow bypassing

3. For `staging`:
   - Branch name pattern: `staging`
   - ✅ Require pull request before merging
   - ✅ Require approvals: 1
   - ✅ Require conversation resolution
   - ✅ Require linear history

4. For `develop` (solo dev):
   - Branch name pattern: `develop`
   - ✅ Require pull request before merging
   - ❌ Require approvals: 0 (for solo development)
   - ✅ Require conversation resolution

5. Repository Settings → General → Pull Requests:
   - ✅ Allow squash merging
   - ✅ Allow rebase merging
   - ✅ Automatically delete head branches

**Outcome:** Branch protection preventing direct commits

---

### Step 14*: Create Pull Request Template
- ✅ Created GitHub PR template
- ✅ Added standard PR sections

**Commands:**
```bash
mkdir -p .github
```

**Files Created:** `.github/pull_request_template.md`

**Complete file content:**
```markdown
## Summary
<!-- Brief description of what this PR does -->

## Related Issue
<!-- Link to Jira ticket, GitHub issue, or related PR -->
Closes #

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Changes Made
<!-- List the main changes -->
-
-

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing locally

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] No new warnings generated
- [ ] Dependent changes merged and published

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Additional Notes
<!-- Any additional context or notes for reviewers -->
```

**Outcome:** Standardized PR format for code reviews

---

### Step 15: Create Git Operations Quick Guide
- ✅ Documented essential Git commands
- ✅ Covered merge, rebase, cherry-pick, conflicts, stash

**Note:** This is a reference document, not mandatory for setup

**Outcome:** Quick reference for Git operations

---

### Step 16: Test Branch Protection
- ✅ Attempted direct push to main (rejected ✅)
- ✅ Created feature branch successfully
- ✅ Created and merged PR to develop

**Test Commands:**
```bash
# Test 1: Try direct commit to main (should fail)
git checkout main
echo "test" >> README.md
git add .
git commit -m "test: direct commit"
git push origin main
# Expected: ❌ Push rejected

# Test 2: Create feature branch (should work)
git checkout develop
git checkout -b feature/test-branch-protection
echo "# Test" > test.md
git add test.md
git commit -m "docs: add test file"
git push origin feature/test-branch-protection
# Expected: ✅ Push successful

# Test 3: Create PR on GitHub and merge
# Expected: ✅ Can merge to develop (no approval needed for solo dev)
```

**Outcome:** Branch protection working correctly

---

### Step 17*: First Feature Branch Workflow
- ✅ Created feature branch from develop
- ✅ Made changes and committed
- ✅ Created PR to develop
- ✅ Merged PR using squash and merge
- ✅ Verified automatic branch deletion

**Workflow:**
```bash
git checkout develop
git checkout -b feature/your-feature-name
# ... make changes ...
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name
# Create PR on GitHub
# Merge using "Squash and merge"
# Branch auto-deleted ✅
```

**Outcome:** Complete PR workflow tested successfully

---

## Phase 4A: Frontend AWS Deployment (COMPLETE)

### Step 18*: AWS CLI Installation and Configuration
- ✅ Installed AWS CLI v2.32.26 via Homebrew
- ✅ Created IAM user: `angular-deployment-user`
- ✅ Attached policies: AmazonS3FullAccess, CloudFrontFullAccess
- ✅ Generated access keys for CLI
- ✅ Configured AWS CLI globally (`~/.aws/credentials`, `~/.aws/config`)
- ✅ Verified configuration: `aws sts get-caller-identity`

**Configuration Location:**
```
~/.aws/
  ├── credentials (Access Key ID, Secret Access Key)
  └── config (region: us-east-1, output: json)
```

**Scope:** Global (all projects on machine)

**Outcome:** AWS CLI configured and authenticated

---

### Step 19*: Create S3 Buckets for All Environments
- ✅ Created 4 S3 buckets with unique IDs
  - `angular-deploy-dev-shree-1767366539`
  - `angular-deploy-qa-shree-1767366539`
  - `angular-deploy-staging-shree-1767366539`
  - `angular-deploy-prod-shree-1767366539`

**Commands:**
```bash
UNIQUE_ID="shree-1767366539"
aws s3 mb s3://angular-deploy-dev-${UNIQUE_ID} --region us-east-1
aws s3 mb s3://angular-deploy-qa-${UNIQUE_ID} --region us-east-1
aws s3 mb s3://angular-deploy-staging-${UNIQUE_ID} --region us-east-1
aws s3 mb s3://angular-deploy-prod-${UNIQUE_ID} --region us-east-1
```

**Outcome:** 4 S3 buckets created in us-east-1 region

---

### Step 20*: Enable Static Website Hosting
- ✅ Configured all 4 buckets for static website hosting
- ✅ Set index document: `index.html`
- ✅ Set error document: `index.html` (for SPA routing)

**Commands:**
```bash
aws s3 website s3://angular-deploy-dev-${UNIQUE_ID} \
  --index-document index.html \
  --error-document index.html
# Repeated for qa, staging, prod
```

**Why error document = index.html?**
Angular SPA routes (/products, /cart) don't exist as files. Returning index.html on 404 allows Angular Router to handle the route.

**Outcome:** All buckets configured as static websites

---

### Step 21*: Configure Public Access and Bucket Policies
- ✅ Disabled "Block Public Access" on all buckets
- ✅ Applied public read bucket policies (s3:GetObject only)

**Commands:**
```bash
# Disable block public access
aws s3api put-public-access-block --bucket bucket-name \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Apply bucket policy
aws s3api put-bucket-policy --bucket bucket-name --policy file://policy.json
```

**Bucket Policy (per bucket):**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::bucket-name/*"
  }]
}
```

**Security:** Read-only public access (users can download, not upload/delete)

**Outcome:** All buckets publicly accessible for static hosting

---

### Step 22*: Build and Deploy to S3
- ✅ Built Angular app for production (`npm run build`)
- ✅ Deployed to development bucket
- ✅ Verified deployment successful

**Build Output:**
```
main-E7O2MXZP.js: 232 KB raw → 62.5 KB gzipped
Build time: ~1.5 seconds
```

**Deployment Commands:**
```bash
# Swap environment config
cp src/assets/config/environment.dev.json \
   dist/angular-release-deployment-frontend/browser/assets/config/environment.json

# Deploy to S3
aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://angular-deploy-dev-${UNIQUE_ID} --delete
```

**Outcome:** Angular app deployed and accessible via S3 URL

---

### Step 23*: Create Deployment Automation Script
- ✅ Created `deploy.sh` script for all environments
- ✅ Features: environment validation, config swapping, S3 sync, error handling
- ✅ Color-coded output for better UX
- ✅ CloudFront invalidation for production

**File:** `deploy.sh`

**Usage:**
```bash
chmod +x deploy.sh
./deploy.sh dev      # Deploy to development
./deploy.sh qa       # Deploy to QA
./deploy.sh staging  # Deploy to staging
./deploy.sh prod     # Deploy to production (includes CloudFront invalidation)
```

**Script Features:**
- Input validation (dev/qa/staging/prod only)
- Automatic environment config swapping
- Build once, deploy anywhere pattern
- CloudFront cache invalidation (prod only)
- Detailed progress reporting
- Error handling with exit codes

**Outcome:** One-command deployment to any environment

---

### Step 24*: Deploy to All Environments
- ✅ Deployed to development (S3)
- ✅ Deployed to QA (S3)
- ✅ Deployed to staging (S3)
- ✅ Deployed to production (S3)
- ✅ Verified all environments accessible

**Live URLs:**
```
Dev:     http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com
QA:      http://angular-deploy-qa-shree-1767366539.s3-website-us-east-1.amazonaws.com
Staging: http://angular-deploy-staging-shree-1767366539.s3-website-us-east-1.amazonaws.com
Prod:    http://angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com
```

**Outcome:** All 4 environments live and functional

---

### Step 25*: Create CloudFront Distribution for Production
- ✅ Created CloudFront distribution via AWS Console
- ✅ Origin: S3 static website endpoint (production bucket)
- ✅ HTTPS enabled automatically
- ✅ Distribution domain: `d29lgch8cdh74n.cloudfront.net`
- ✅ Distribution ID: `E1QKKABZX5LKQQ`

**Configuration:**
- Distribution name: `angular-prod-distribution`
- Distribution type: Single website or app
- Origin: `angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com`
- Viewer protocol: Redirect HTTP to HTTPS
- Price class: All edge locations (450+ worldwide)
- WAF: Disabled (cost optimization for learning)

**Outcome:** CloudFront distribution created and deployed

---

### Step 26*: Configure CloudFront Custom Error Responses
- ✅ Configured 403 Forbidden → `/index.html` (200 OK)
- ✅ Configured 404 Not Found → `/index.html` (200 OK)
- ✅ Error caching TTL: 10 seconds

**Why This is Critical:**
CloudFront looks for /products file → doesn't exist → returns error → custom error response returns index.html → Angular handles route.

**Configuration:**
```
Error code: 403
Response page: /index.html
Response code: 200 OK
Cache TTL: 10 seconds

Error code: 404
Response page: /index.html
Response code: 200 OK
Cache TTL: 10 seconds
```

**Outcome:** SPA routing works correctly via CloudFront

---

### Step 27*: Test CloudFront Distribution
- ✅ Root URL working: `https://d29lgch8cdh74n.cloudfront.net`
- ✅ Direct route access working: `https://d29lgch8cdh74n.cloudfront.net/test-route`
- ✅ HTTPS enabled (secure connection)
- ✅ No 403 errors on Angular routes
- ✅ Production environment config loaded correctly

**Outcome:** CloudFront fully functional with SPA support

---

### Step 28*: Update Deployment Script with CloudFront Invalidation
- ✅ Updated `deploy.sh` to invalidate CloudFront cache on production deployments
- ✅ Saved CloudFront details to `.env.aws`
- ✅ Tested production deployment with automatic cache invalidation

**Updated deploy.sh features:**
```bash
# Production deployment now includes:
1. Build Angular app
2. Swap environment config
3. Upload to S3
4. Invalidate CloudFront cache (/* paths)
5. Show both S3 and CloudFront URLs
```

**File:** `.env.aws`
```
UNIQUE_ID=shree-1767366539
CLOUDFRONT_DISTRIBUTION_ID=E1QKKABZX5LKQQ
CLOUDFRONT_DOMAIN=d29lgch8cdh74n.cloudfront.net
```

**Outcome:** Production deployments automatically update CloudFront

---

### Step 29: Create Comprehensive AWS Knowledge Guide
- ✅ Created `AWS-KNOWLEDGE-GUIDE.md` (1000+ lines)
- ✅ Covers S3 deep dive (buckets, policies, static hosting, costs)
- ✅ Covers CloudFront deep dive (CDN, edge locations, caching, invalidation)
- ✅ Addresses user questions (CloudFront vs S3, costs, multi-env strategy)
- ✅ Includes troubleshooting guide
- ✅ Production best practices
- ✅ Real-world examples
- ✅ Cost analysis and optimization

**Topics covered:**
- AWS Fundamentals (IAM, CLI, global config)
- Amazon S3 (buckets, policies, static hosting, ARN, regions, costs)
- CloudFront CDN (distributions, origins, caching, TTL, invalidation, HTTPS)
- Production vs Learning setups
- Cost analysis (S3 vs S3+CloudFront)
- Deployment workflows
- Troubleshooting guide
- Best practices (security, performance, cost)
- Real-world examples (5 scenarios)

**Outcome:** Complete AWS reference guide for future use

---

## Phase 5: CI/CD for Serverless (S3 + CloudFront) - COMPLETE ✅

### Step 30*: Create GitHub Actions Workflow Directory
- ✅ Created `.github/workflows/` directory
- ✅ Standard location for GitHub Actions workflow files
- ✅ Automatically detected by GitHub

**Outcome:** Workflow directory ready for CI/CD configuration

---

### Step 31*: Create Multi-Environment CI/CD Workflow
- ✅ Created `.github/workflows/deploy-s3.yml` (500+ lines)
- ✅ 8 jobs configured:
  1. Lint & Format Check
  2. Unit Tests
  3. Build Angular App
  4. Deploy to Development (auto on push to develop)
  5. Deploy to QA (manual trigger only)
  6. Deploy to Staging (auto on push to staging)
  7. Deploy to Production (auto on push to main with approval)
  8. Deployment Notifications (extensible)

**Workflow Features:**
- Environment-specific configuration swapping
- Build artifact optimization with caching
- AWS credentials management via GitHub Secrets
- CloudFront cache invalidation (production only)
- Manual approval gates for production
- Deployment summary with URLs
- Pull request testing (no deployment)

**Triggers:**
```yaml
- Push to develop → Deploy to dev
- Push to staging → Deploy to staging
- Push to main → Deploy to prod (with approval)
- Manual trigger → Deploy to any environment
- Pull request → Run tests only
```

**Outcome:** Complete automated CI/CD pipeline configured

---

### Step 32*: Add Inline Documentation for Alternative Approaches
- ✅ Comprehensive comments explaining deployment alternatives
- ✅ Option 1: Using deploy.sh (Bash Script)
  - Complete example with environment variables
  - Explains what steps it replaces
  - Pros/cons documented
- ✅ Option 2: Using deploy.mjs (Node.js Script)
  - Complete example with environment variables
  - Explains what steps it replaces
  - Pros/cons documented
- ✅ Rationale for direct commands in CI/CD (8 reasons)

**Comment Location:** Inline at deployment step (as requested)

**Outcome:** Clear reference for alternative deployment approaches

---

### Step 33*: Create Cross-Platform Deployment Script
- ✅ Created `deploy.mjs` (260+ lines)
- ✅ Node.js-based deployment script
- ✅ Works on Windows, macOS, and Linux
- ✅ Feature parity with deploy.sh

**Features:**
- ANSI color-coded output
- Cross-platform path handling
- Same 4-step deployment process as deploy.sh
- Environment configuration swapping
- S3 deployment with AWS CLI
- CloudFront cache invalidation (production)
- Comprehensive error handling
- Educational comments

**Outcome:** Windows-compatible deployment script for local use

---

### Step 34*: Add Deployment npm Scripts
- ✅ Updated `package.json` with deployment commands
- ✅ Bash script wrappers: `deploy:dev`, `deploy:qa`, `deploy:staging`, `deploy:prod`
- ✅ Node.js script wrappers: `deploy:dev:node`, `deploy:qa:node`, `deploy:staging:node`, `deploy:prod:node`
- ✅ Help command: `deploy:help`
- ✅ Documentation comments explaining usage

**Usage:**
```bash
npm run deploy:help          # Show all options
npm run deploy:dev           # Deploy to dev (bash)
npm run deploy:dev:node      # Deploy to dev (Node.js)
npm run deploy:prod          # Deploy to prod (bash)
npm run deploy:prod:node     # Deploy to prod (Node.js)
```

**Outcome:** Easy-to-remember deployment commands

---

### Step 35*: Create CI/CD Setup Guide
- ✅ Created `CICD-SETUP-GUIDE.md` (700+ lines)
- ✅ Step-by-step GitHub Secrets configuration
- ✅ Environment protection rules setup
- ✅ Complete workflow explanation (triggers, jobs, steps)
- ✅ Deployment workflows for each environment
- ✅ Troubleshooting guide with common errors and solutions
- ✅ Security best practices
- ✅ Cost analysis
- ✅ Advanced configurations (Slack, tags, multi-account)

**Sections:**
1. Prerequisites
2. Configure GitHub Secrets (5 secrets)
3. Configure GitHub Environments (4 environments with protection rules)
4. Understanding the Workflow
5. Test the CI/CD Pipeline
6. Deployment Workflows (dev/staging/prod)
7. Troubleshooting
8. Best Practices
9. CI/CD vs Manual Deployment
10. Monitoring Deployments
11. Cost Analysis
12. Security Checklist

**Outcome:** Complete guide for setting up and using CI/CD

---

### Step 36*: Create Deployment Options Guide
- ✅ Created `DEPLOYMENT-OPTIONS.md` (300+ lines)
- ✅ When to use each deployment method
- ✅ Decision trees for method selection
- ✅ Real-world scenarios and examples
- ✅ Platform compatibility matrix
- ✅ Best practices

**Deployment Methods Documented:**
1. GitHub Actions (recommended for production)
2. Bash Script (emergency manual deployments)
3. Node.js Script (cross-platform reference)

**Includes:**
- Quick reference table
- Detailed comparison
- Real-world scenarios (4 scenarios)
- Environment-specific recommendations
- Troubleshooting guide
- Learning resources

**Outcome:** Clear guidance on choosing deployment approaches

---

### Step 37*: Create GitHub Actions Monitoring Guide
- ✅ Created `GITHUB-ACTIONS-MONITORING-GUIDE.md` (500+ lines)
- ✅ How to access GitHub Actions dashboard
- ✅ Understanding workflow status indicators
- ✅ Viewing deployment details step-by-step
- ✅ Reading deployment summaries (user's specific request!)
- ✅ Monitoring live deployments in real-time
- ✅ Checking deployment history
- ✅ Troubleshooting failed deployments with solutions
- ✅ Using GitHub CLI for monitoring
- ✅ Deployment summary examples

**Sections:**
1. Accessing GitHub Actions
2. Understanding the Workflow Dashboard
3. Viewing Deployment Details
4. Reading Deployment Summaries
5. Monitoring Live Deployments
6. Checking Deployment History
7. Troubleshooting Failed Deployments
8. Using GitHub CLI for Monitoring
9. Deployment Summary Checklist
10. Best Practices for Monitoring
11. Deployment Summary Examples
12. Quick Reference Card

**Outcome:** Complete guide for monitoring CI/CD deployments

---

### Step 38*: Commit and Push Phase 5 to GitHub
- ✅ Staged all Phase 5 changes (6 files, 2,451 lines)
- ✅ Created comprehensive commit message
- ✅ Committed to develop branch (commit: ab01fc1)
- ✅ Pushed to GitHub remote
- ✅ Pre-commit hooks ran successfully (lint-staged, Prettier)

**Files Committed:**
1. `.github/workflows/deploy-s3.yml` - CI/CD workflow
2. `deploy.mjs` - Cross-platform deployment script
3. `package.json` - Updated with deployment scripts
4. `CICD-SETUP-GUIDE.md` - Setup guide
5. `DEPLOYMENT-OPTIONS.md` - Deployment methods guide
6. `GITHUB-ACTIONS-MONITORING-GUIDE.md` - Monitoring guide

**Commit Message Highlights:**
- Phase 5 Complete - CI/CD for Serverless
- Multi-environment CI/CD pipeline
- Cross-platform deployment support
- Comprehensive documentation (3 guides)
- Inline alternative approach documentation

**Outcome:** Phase 5 changes committed and pushed to GitHub

---

## Summary Statistics

**Total Mandatory Steps Completed:** 31 (marked with *)
**Total Steps Completed:** 38
**Phases Completed:** 5 (Phases 1, 2, 2.5, 3, 4A, 5)
**Phases In Progress:** 0
**Configuration Files Created:** 32+
**Documentation Files Created:** 17+
**Lines of Code/Documentation Added:**
- Phase 1-4A: ~3,500 lines
- Phase 5: ~2,500 lines
- **Total: ~6,000 lines**

---

## Key Achievements

✅ **Production-Grade Setup:**
- TypeScript strict mode
- ESLint + Prettier + Husky
- Conventional commits with commitlint
- Pre-commit hooks for code quality

✅ **Runtime Configuration:**
- Build once, deploy everywhere pattern
- Environment-specific configs loaded at runtime
- No rebuild required for environment changes

✅ **Enterprise Git Workflow:**
- Git Flow branching strategy (main/staging/develop)
- Branch protection rules with PR requirements
- PR templates for consistent code reviews
- Automated branch cleanup

✅ **AWS Cloud Deployment:**
- Multi-environment S3 static hosting (dev, qa, staging, prod)
- CloudFront CDN with HTTPS (production)
- Automated deployment script (deploy.sh)
- Cross-platform deployment script (deploy.mjs)
- Cache invalidation automation
- Global edge network (450+ locations)

✅ **CI/CD Automation:**
- GitHub Actions multi-environment pipeline
- Automated linting, testing, building, deployment
- Manual approval gates for production
- Environment-specific configuration swapping
- CloudFront cache invalidation (production)
- Pull request testing without deployment
- Deployment monitoring and summaries

✅ **Documentation:**
- Every major feature documented
- Step-by-step setup guides
- Complete file contents included
- Comprehensive AWS knowledge guide (1000+ lines)
- CI/CD setup guide (700+ lines)
- Deployment options guide (300+ lines)
- GitHub Actions monitoring guide (500+ lines)
- No external file lookups required

---

## Live Deployments

**Development:**
- http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com

**QA:**
- http://angular-deploy-qa-shree-1767366539.s3-website-us-east-1.amazonaws.com

**Staging:**
- http://angular-deploy-staging-shree-1767366539.s3-website-us-east-1.amazonaws.com

**Production:**
- https://d29lgch8cdh74n.cloudfront.net (CloudFront - HTTPS, CDN)
- http://angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com (S3 Direct)

---

## Upcoming Phases

- **Phase 4B:** Frontend Docker Deployment (~3-4 hours)
- **Phase 6:** Frontend Versioning & Tagging (~2-3 hours)
- **Phase 7:** Production Deployment Strategies (Blue-Green, Canary) (~4-5 hours)
- **Phase 8:** Cross-Repo Integration Testing (~3-4 hours)
- **Phase 9:** Monitoring & Observability (~3-4 hours)

**Estimated Time Remaining:** ~15-20 hours of learning

---

## How to Use This Checklist

### For Fresh Setup:
1. Follow **mandatory steps (marked with *)** sequentially
2. Copy complete file contents provided
3. Verify outcome before moving to next step
4. Optional steps provide reference documentation

### For Troubleshooting:
1. Identify which phase you're in
2. Review completed steps for that phase
3. Check file contents match exactly
4. Verify expected outcomes

### For Team Onboarding:
1. Share this checklist with new team members
2. Use as training roadmap
3. Each step builds on previous ones
4. All file contents self-contained

---

**Last Updated:** 2026-01-03 (Phase 5 Complete)
**Current Phase:** Phase 5 - CI/CD for Serverless - COMPLETE ✅
**Next Phase:** Phase 4B (Docker Deployment) or Phase 6 (Versioning & Tagging)
**Project Completion:** ~60% complete

**Note:** This document is updated after each major phase completion.

---

## Next Steps (To Complete CI/CD Setup)

Before CI/CD workflows can run successfully, complete these configuration steps:

### 1. Configure GitHub Secrets
Navigate to: `Repository → Settings → Secrets and variables → Actions`

Create these 5 repository secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `UNIQUE_ID` - Your unique identifier (shree-1767366539)
- `CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID
- `CLOUDFRONT_DOMAIN` - CloudFront domain name

**Reference:** See [CICD-SETUP-GUIDE.md](CICD-SETUP-GUIDE.md) for detailed instructions

### 2. Configure GitHub Environments
Navigate to: `Repository → Settings → Environments`

Create these 4 environments:
- `development` (no protection)
- `qa` (no protection)
- `staging` (no protection)
- `production` (required reviewers: add yourself)

**Reference:** See [CICD-SETUP-GUIDE.md](CICD-SETUP-GUIDE.md) Step 1

### 3. Test the CI/CD Pipeline
```bash
# Make a small change and push to develop
git checkout develop
echo "// CI/CD test" >> src/app/app.component.ts
git add .
git commit -m "test: verify CI/CD pipeline"
git push origin develop
```

Monitor the workflow at: `Repository → Actions`

**Reference:** See [GITHUB-ACTIONS-MONITORING-GUIDE.md](GITHUB-ACTIONS-MONITORING-GUIDE.md) for monitoring instructions

---

## Future Testing Scenarios (Pending)

These realistic workflow scenarios will be tested in future sessions:

1. **5 PRs Merged, 4 Features Go Live**
   - Scenario: 5 feature PRs merged to develop, but only 4 features should be deployed this sprint
   - Flow: Feature flags, selective cherry-picking, or release branch strategy
   - Must follow: Proper PR process (no direct pushes)

2. **Hotfix Flow**
   - Scenario: Critical bug found in production requiring immediate fix
   - Flow: Create hotfix branch from main → fix → PR → approve → merge → auto-deploy
   - Must follow: Emergency approval process, proper documentation

3. **Rollback Flow**
   - Scenario: Production deployment causes issues, need to rollback
   - Flow: Revert commit → PR → approve → merge → auto-deploy previous version
   - Must follow: Incident documentation, post-mortem process

4. **Additional Scenarios to Design**
   - Conflicting PRs requiring manual merge
   - Failed deployment recovery
   - Partial environment failure
   - Cross-environment promotion timing

**Note:** All flows must use proper PR-based workflows. No direct pushes to protected branches.
