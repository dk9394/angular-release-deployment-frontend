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

## Phase 4A: Frontend AWS Deployment (In Progress)

### Step 18: AWS Deployment Guide Created
- ✅ Created comprehensive AWS deployment guide
- ✅ Documented S3 bucket setup for 4 environments
- ✅ Documented CloudFront CDN configuration
- ✅ Created deployment automation scripts

**Note:** Reference AWS-DEPLOYMENT-GUIDE.md for detailed steps

**Next Steps:**
1. Create AWS account
2. Install AWS CLI
3. Create S3 buckets for dev, qa, staging, production
4. Configure static website hosting
5. Deploy Angular build
6. Set up CloudFront for production

**Status:** 🔄 Pending user AWS setup

---

## Summary Statistics

**Total Mandatory Steps Completed:** 14 (marked with *)
**Total Steps Completed:** 18+
**Phases Completed:** 3
**Phases In Progress:** 1 (Phase 4A)
**Configuration Files Created:** 25+
**Documentation Files Created:** 8+

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

✅ **Documentation:**
- Every major feature documented
- Step-by-step setup guides
- Complete file contents included
- No external file lookups required

---

## Upcoming Phases

- **Phase 4B:** Frontend Docker Deployment
- **Phase 5:** Frontend CI/CD Quality Gates
- **Phase 6:** Frontend CI/CD Build & Deploy
- **Phase 7:** Frontend Versioning
- **Phase 8:** Production Deployment Strategies
- **Phase 9:** Cross-Repo Integration

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

**Last Updated:** 2026-01-02
**Current Phase:** Phase 4A - AWS Deployment (Step 18)
**Next Step:** Complete AWS account setup and S3 deployment

**Note:** This document will be updated after each major step going forward.
