# Deployment Workflow Mental Model

**Complete Guide to Understanding Branches, Environments, and Deployments**

---

## Table of Contents

1. [The Three-Layer Architecture](#the-three-layer-architecture)
2. [How Environments Work Together](#how-environments-work-together)
3. [The Complete Mapping Table](#the-complete-mapping-table)
4. [Two Workflow Behaviors](#two-workflow-behaviors)
5. [QA Environment - The Flexible Playground](#qa-environment---the-flexible-playground)
6. [Decision Trees and Flow Diagrams](#decision-trees-and-flow-diagrams)
7. [Real-World Examples](#real-world-examples)
8. [Common Mistakes and How to Avoid Them](#common-mistakes-and-how-to-avoid-them)
9. [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## The Three-Layer Architecture

Think of your deployment system as **three parallel tracks** that work together:

```
┌─────────────────────────────────────────────────────────────┐
│                  LAYER 1: CODE (Git Branches)                │
├─────────────────────────────────────────────────────────────┤
│  develop  →  staging  →  main                                │
│  (branch)    (branch)    (branch)                            │
│                                                              │
│  Purpose: Controls WHAT code gets built                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│         LAYER 2: WORKFLOW (GitHub Actions)                   │
├─────────────────────────────────────────────────────────────┤
│  development  →  staging  →  production                      │
│  (environment)  (environment)  (environment + approval)      │
│                                                              │
│  Purpose: Controls WHERE code gets deployed                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│       LAYER 3: INFRASTRUCTURE (AWS S3 + CloudFront)          │
├─────────────────────────────────────────────────────────────┤
│  angular-deploy-dev  →  angular-deploy-staging  →           │
│  (S3 bucket)            (S3 bucket)                          │
│                                                              │
│  angular-deploy-prod + CloudFront CDN                        │
│  (S3 bucket)           (Global delivery)                     │
│                                                              │
│  Purpose: Physical infrastructure hosting your app          │
└─────────────────────────────────────────────────────────────┘
```

### Key Insight

**The workflow file (`.github/workflows/deploy-s3.yml`) is the glue that connects all three layers.**

> Git branches control WHAT code gets built, the workflow file controls WHERE it gets deployed, and the config swap controls HOW the app behaves after deployment.

---

## How Environments Work Together

There are THREE different types of "environments" in your system:

### 1. Application Environments (Config Files)

**Location**: `src/assets/config/`

**Files**:
- `environment.dev.json`
- `environment.qa.json`
- `environment.staging.json`
- `environment.production.json`

**What they control**:
```json
{
  "name": "development",
  "production": false,
  "apiUrl": "https://api-dev.example.com",
  "authUrl": "https://auth-dev.example.com",
  "features": {
    "enableAnalytics": false,
    "enableLogging": true,
    "enableDebugMode": true
  }
}
```

**Purpose**: Tell your Angular app how to behave (which backend to connect to, what features to enable, etc.)

**Loaded**: At runtime in the user's browser

---

### 2. GitHub Environments (Workflow Protection)

**Location**: GitHub Repository → Settings → Environments

**Names**:
- `development`
- `qa`
- `staging`
- `production`

**What they control**:
- Manual approval gates (production requires approval before deployment)
- Deployment history tracking
- Deployment URLs displayed in GitHub UI
- Environment-specific secrets (optional, not used in this project)

**Purpose**: Control who can deploy and provide audit trail

---

### 3. AWS Environments (Infrastructure)

**Location**: AWS S3 buckets

**Names**:
- `angular-deploy-dev-shree-1767366539`
- `angular-deploy-qa-shree-1767366539`
- `angular-deploy-staging-shree-1767366539`
- `angular-deploy-prod-shree-1767366539`

**Additional infrastructure**:
- Production also has CloudFront distribution: `d29lgch8cdh74n.cloudfront.net`

**Purpose**: Physical servers hosting your application files

---

### How They Sync

**They DON'T sync automatically** - YOU sync them via the workflow file:

```yaml
# .github/workflows/deploy-s3.yml connects everything:

on:
  push:
    branches:
      - develop  # ← Git branch (Layer 1)

deploy-dev:
  if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
  environment:
    name: development  # ← GitHub Environment (Layer 2)
  steps:
    - name: Swap environment configuration
      run: |
        cp src/assets/config/environment.dev.json \  # ← Config file
           dist/.../environment.json

    - name: Deploy to S3
      run: |
        aws s3 sync ... s3://angular-deploy-dev-shree-1767366539  # ← AWS Infrastructure (Layer 3)
```

**The workflow file is the single source of truth that connects all three layers.**

---

## The Complete Mapping Table

This is your master reference - memorize this table:

| Git Branch | Trigger Type | GitHub Workflow Event | GitHub Environment | Config Swapped | S3 Bucket | CloudFront? | Approval? |
|------------|-------------|----------------------|-------------------|----------------|-----------|-------------|-----------|
| `develop` | Auto (push) | `push` | `development` | `environment.dev.json` | `angular-deploy-dev-*` | ❌ No | ❌ No |
| `staging` | Auto (push) | `push` | `staging` | `environment.staging.json` | `angular-deploy-staging-*` | ❌ No | ❌ No |
| `main` | Auto (push) | `push` | `production` | `environment.production.json` | `angular-deploy-prod-*` | ✅ Yes | ✅ Yes |
| ANY branch | Manual | `workflow_dispatch` | `qa` | `environment.qa.json` | `angular-deploy-qa-*` | ❌ No | ❌ No |
| feature/* | ❌ Never triggers | N/A | N/A | N/A | N/A | N/A | N/A |

### Key Points

- **Only 3 branches trigger automatic deployments**: `develop`, `staging`, `main`
- **Feature branches NEVER trigger the workflow** (not in the `push.branches` list)
- **QA is special**: Manual trigger only, accepts ANY branch
- **Production is protected**: Requires manual approval before deployment

---

## Two Workflow Behaviors

Your workflow has **two distinct behaviors** depending on how it's triggered:

### Behavior 1: Pull Request (No Deployment)

**When it happens**:
- You create a PR to `develop`, `staging`, or `main`
- You update an existing PR by pushing new commits

**Configuration**:
```yaml
on:
  pull_request:
    branches:
      - develop
      - staging
      - main
```

**What runs**:
```
Event: pull_request
GitHub Values:
  github.event_name = 'pull_request'
  github.ref = 'refs/heads/feature/new-feature' (source branch)

Jobs Execution:
  ✅ lint          (runs - no conditions)
  ✅ test          (runs - no conditions)
  ✅ build         (runs - no conditions)
  ❌ deploy-dev    (SKIPPED - fails: github.event_name == 'push')
  ❌ deploy-staging (SKIPPED - fails: github.event_name == 'push')
  ❌ deploy-prod    (SKIPPED - fails: github.event_name == 'push')
```

**Purpose**: Code quality gate - ensures code passes linting and tests before merging

**Result**: NO deployment, just validation

---

### Behavior 2: Push to Branch (With Deployment)

**When it happens**:
- You push directly to `develop`, `staging`, or `main`
- You merge a PR (merging creates a push to the target branch)

**Configuration**:
```yaml
on:
  push:
    branches:
      - develop
      - staging
      - main
```

**What runs** (example: push to develop):
```
Event: push
GitHub Values:
  github.event_name = 'push'
  github.ref = 'refs/heads/develop'

Jobs Execution:
  ✅ lint          (runs - no conditions)
  ✅ test          (runs - no conditions)
  ✅ build         (runs - no conditions)
  ✅ deploy-dev    (RUNS - passes: github.ref == 'refs/heads/develop' && github.event_name == 'push')
  ❌ deploy-staging (SKIPPED - fails: github.ref != 'refs/heads/staging')
  ❌ deploy-prod    (SKIPPED - fails: github.ref != 'refs/heads/main')
```

**Purpose**: Full CI/CD pipeline - build and deploy

**Result**: Code is deployed to the corresponding environment

---

### The Three Gatekeepers

Every deployment job must pass through three gatekeepers:

```
Gatekeeper 1: Branch Filter (workflow triggers)
   │
   ├─ Is branch develop, staging, or main?
   │   YES → Workflow starts
   │   NO → Workflow doesn't even run (feature branches stop here)
   │
   ↓
Gatekeeper 2: Event Type Check
   │
   ├─ Is this a 'push' event (not 'pull_request')?
   │   YES → Deployment jobs can run
   │   NO → Only lint/test/build run
   │
   ↓
Gatekeeper 3: Branch Match
   │
   └─ Does branch match the deployment target?
       github.ref == 'refs/heads/develop' → deploy-dev runs
       github.ref == 'refs/heads/staging' → deploy-staging runs
       github.ref == 'refs/heads/main' → deploy-prod runs
```

---

### Comparison Table

| Aspect | Pull Request Workflow | Push Workflow |
|--------|----------------------|---------------|
| **Trigger** | Creating/updating PR | git push or merge PR |
| **Event Name** | `pull_request` | `push` |
| **Branch** | Source branch of PR | Target branch |
| **Lint Job** | ✅ Runs | ✅ Runs |
| **Test Job** | ✅ Runs | ✅ Runs |
| **Build Job** | ✅ Runs | ✅ Runs |
| **Deploy Jobs** | ❌ Skipped | ✅ Run (if branch matches) |
| **Purpose** | Quality gate | Deployment |
| **User sees** | PR checks pass/fail | Deployment status |

---

### Why This Design?

**Benefit 1: Fast Feedback on PRs**
- Developers get immediate feedback if their code passes lint/test
- No need to wait for deployment
- Prevents bad code from being merged

**Benefit 2: Safe Deployments**
- Only merged code gets deployed
- No accidental deployments from open PRs
- Clear separation between validation and deployment

**Benefit 3: Cost Efficient**
- Don't deploy every PR commit to AWS
- Only deploy when code is actually merged
- Saves S3 sync operations and CloudFront invalidations

---

## QA Environment - The Flexible Playground

QA is fundamentally different from Dev/Staging/Prod:

### The Helicopter vs. Train Analogy

```
Dev/Staging/Prod:  Train on rails
   ↓
   Automatic, follows branch flow, predictable

QA:  Helicopter
   ↓
   Manual, lands wherever you want, flexible
```

---

### How QA Differs

**Dev/Staging/Prod**:
```yaml
deploy-dev:
  if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
      ↑ MUST be develop branch
```

**QA**:
```yaml
deploy-qa:
  if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'qa'
      ↑ NO branch restriction - accepts ANY branch!
```

---

### How to Trigger QA Deployment

**Step 1**: Go to GitHub Actions
```
Repository → Actions → "Deploy to AWS S3" (left sidebar)
```

**Step 2**: Click "Run workflow" button (top right)

**Step 3**: Fill the form
```
Use workflow from: [Select ANY branch ▼]
Environment to deploy: [Select "qa" ▼]
```

**Step 4**: Click "Run workflow"

---

### QA Use Cases

#### Use Case 1: Test Feature Before Merging
```
Scenario: Working on feature/dark-mode

Steps:
1. Push feature branch: git push origin feature/dark-mode
2. Manually trigger workflow
   Branch: feature/dark-mode
   Environment: qa
3. QA tests at: http://angular-deploy-qa-*.amazonaws.com
4. Get feedback
5. Fix issues
6. Redeploy to QA
7. Once approved, merge to develop
```

#### Use Case 2: Test Hotfix
```
Scenario: Critical bug in production

Steps:
1. Create hotfix branch: git checkout -b hotfix/payment-error main
2. Fix the bug
3. Push: git push origin hotfix/payment-error
4. Manually trigger workflow
   Branch: hotfix/payment-error
   Environment: qa
5. QA verifies fix works
6. Create PR to main
7. Merge and auto-deploy to production
```

#### Use Case 3: Reproduce Production Issue
```
Scenario: Bug reported in production

Steps:
1. Manually trigger workflow
   Branch: main
   Environment: qa
2. QA reproduces issue in safe environment
3. Create fix branch
4. Test fix in QA
5. Deploy to production
```

---

### QA Deployment Matrix

| Branch Selected | Config Used | S3 Bucket | Backend Connected |
|----------------|-------------|-----------|-------------------|
| `develop` | `environment.qa.json` | `angular-deploy-qa-*` | QA backend |
| `staging` | `environment.qa.json` | `angular-deploy-qa-*` | QA backend |
| `main` | `environment.qa.json` | `angular-deploy-qa-*` | QA backend |
| `feature/new-feature` | `environment.qa.json` | `angular-deploy-qa-*` | QA backend |
| `hotfix/bug-fix` | `environment.qa.json` | `angular-deploy-qa-*` | QA backend |

**Key insight**: The config file is ALWAYS `environment.qa.json`, regardless of which branch you select. Only the **code** comes from the selected branch.

---

## Decision Trees and Flow Diagrams

### Complete Workflow Decision Tree

```
GitHub Event Received
    │
    ├─── Is it workflow_dispatch (manual trigger)?
    │    YES → User selected environment from dropdown
    │         │
    │         ├─── Selected "dev"?
    │         │    YES → Build from selected branch → Deploy to dev
    │         │
    │         ├─── Selected "qa"?
    │         │    YES → Build from selected branch → Deploy to QA
    │         │
    │         ├─── Selected "staging"?
    │         │    YES → Build from selected branch → Deploy to staging
    │         │
    │         └─── Selected "prod"?
    │              YES → Build from selected branch → Deploy to prod (with approval)
    │
    ├─── Is it pull_request?
    │    YES → Run lint, test, build
    │         → Skip all deployment jobs
    │         → Show check status on PR
    │
    └─── Is it push?
         YES → Check which branch
              │
              ├─── Branch == develop?
              │    YES → Run lint, test, build, deploy-dev
              │
              ├─── Branch == staging?
              │    YES → Run lint, test, build, deploy-staging
              │
              ├─── Branch == main?
              │    YES → Run lint, test, build, deploy-prod (with approval)
              │
              └─── Branch == feature/*?
                   NO MATCH → Workflow doesn't run (not in push.branches list)
```

---

### Development Flow Diagram

```
Feature Development:
┌─────────────────────────┐
│ 1. Create feature branch │
│    from develop         │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ 2. Make changes         │
│    git push origin      │
│    feature/new-feature  │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Workflow:               │
│ ❌ Does NOT run         │
│ (branch not in list)    │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ 3. Create PR to develop │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Workflow runs:          │
│ ✅ Lint                 │
│ ✅ Test                 │
│ ✅ Build                │
│ ❌ NO deployment        │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ 4. PR approved & merged │
│    (creates push to     │
│     develop)            │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Workflow runs:          │
│ ✅ Lint                 │
│ ✅ Test                 │
│ ✅ Build                │
│ ✅ Deploy to dev        │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Live at:                │
│ http://angular-deploy-  │
│ dev-*.amazonaws.com     │
└─────────────────────────┘
```

---

### Production Deployment Flow

```
┌─────────────────────────┐
│ Code tested in staging  │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Create PR:              │
│ staging → main          │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Workflow runs:          │
│ ✅ Lint                 │
│ ✅ Test                 │
│ ✅ Build                │
│ ❌ NO deployment        │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ PR approved & merged    │
│ (creates push to main)  │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Workflow starts:        │
│ ✅ Lint                 │
│ ✅ Test                 │
│ ✅ Build                │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ ⏸️  PAUSES FOR APPROVAL │
│ "Review pending"        │
│ Yellow banner on GitHub │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Team lead clicks:       │
│ "Review deployments"    │
│ → "Approve and deploy"  │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ ✅ Deploy to S3         │
│ ✅ Invalidate CloudFront│
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│ Live at:                │
│ https://d29lgch8cdh74n. │
│ cloudfront.net          │
│ (1-2 min propagation)   │
└─────────────────────────┘
```

---

## Real-World Examples

### Example 1: Normal Feature Development

**Scenario**: Adding a new login page

```bash
# 1. Create feature branch
git checkout -b feature/login-page develop

# 2. Develop and test locally
# ... make changes ...
npm start  # Test locally at localhost:4200

# 3. Push feature branch
git push origin feature/login-page
# ❌ Workflow does NOT run (feature branch not in trigger list)

# 4. Create PR on GitHub UI
# feature/login-page → develop
# ✅ Workflow runs: lint, test, build (NO deployment)
# PR shows: "All checks have passed ✅"

# 5. Team reviews code
# Approves PR

# 6. Merge PR (squash and merge)
# This creates a push to develop
# ✅ Workflow runs: lint, test, build, deploy-dev
# Live at: http://angular-deploy-dev-*.amazonaws.com

# 7. QA tests in dev environment
# Finds minor issue with login button styling

# 8. Create fix
git checkout feature/login-page
# ... fix styling ...
git push origin feature/login-page

# 9. Optional: Deploy to QA for testing
# GitHub Actions → Run workflow
# Branch: feature/login-page
# Environment: qa
# QA verifies fix at: http://angular-deploy-qa-*.amazonaws.com

# 10. Update PR, get approval, merge
# Auto-deploys to dev again

# 11. After dev testing, promote to staging
git checkout staging
git merge develop
git push origin staging
# ✅ Auto-deploys to staging

# 12. After staging approval, deploy to production
git checkout main
git merge staging
git push origin main
# ⏸️  Requires manual approval
# ✅ Deploys to production with CloudFront
```

---

### Example 2: Emergency Hotfix

**Scenario**: Payment processing broken in production

```bash
# 1. Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/payment-processor

# 2. Fix the bug
# ... make fix ...

# 3. Push hotfix branch
git push origin hotfix/payment-processor
# ❌ Workflow does NOT run

# 4. Deploy to QA for urgent testing
# GitHub Actions → Run workflow
# Branch: hotfix/payment-processor
# Environment: qa
# ✅ QA verifies fix works

# 5. Create PR to main
# hotfix/payment-processor → main
# ✅ Workflow runs: lint, test, build (NO deployment)

# 6. Get emergency approval
# Manager approves PR

# 7. Merge to main
# ✅ Workflow runs, pauses for approval
# Manager clicks "Approve and deploy"
# ✅ Deploys to production

# 8. Backport to develop and staging
git checkout develop
git cherry-pick <hotfix-commit-sha>
git push origin develop
# ✅ Auto-deploys to dev

git checkout staging
git cherry-pick <hotfix-commit-sha>
git push origin staging
# ✅ Auto-deploys to staging
```

---

### Example 3: Testing Multiple Features in QA

**Scenario**: QA wants to test 3 different features

```bash
# Feature 1: Dark mode (in feature/dark-mode branch)
# Deploy to QA
GitHub Actions → Run workflow
Branch: feature/dark-mode
Environment: qa
# QA tests, provides feedback

# Feature 2: User profiles (in feature/user-profiles branch)
# Deploy to QA (overwrites dark mode deployment)
GitHub Actions → Run workflow
Branch: feature/user-profiles
Environment: qa
# QA tests, provides feedback

# Feature 3: Notifications (in feature/notifications branch)
# Deploy to QA (overwrites user profiles deployment)
GitHub Actions → Run workflow
Branch: feature/notifications
Environment: qa
# QA tests, approves

# Note: QA bucket can only hold ONE deployment at a time
# Each new QA deployment overwrites the previous one
# This is by design - QA is for sequential testing
```

---

## Common Mistakes and How to Avoid Them

### Mistake 1: "Feature branch deployed to dev!"

**What you think happened**:
```bash
git push origin feature/new-feature
# You see a deployment to dev
```

**What actually happened**:
```bash
# You were actually on develop branch
git push origin develop
# This correctly deployed to dev
```

**How to verify**:
```bash
# Check GitHub Actions workflow run
# Look at: "Event: push" + "Branch: develop"
# If it says Branch: develop → CORRECT behavior
# If it says Branch: feature/* → IMPOSSIBLE (workflow won't run)
```

**How to avoid**:
```bash
# Always check current branch before pushing
git branch  # Shows current branch with *
git push origin $(git branch --show-current)  # Pushes current branch explicitly
```

---

### Mistake 2: "PR created but nothing deployed"

**What you think should happen**:
```bash
# Create PR feature/new-feature → develop
# Expect deployment to dev
```

**Why this is wrong**:
```
PR creates a pull_request event, not a push event
Deployment jobs check: github.event_name == 'push'
This check fails, so NO deployment
```

**Correct understanding**:
```
PR → Runs lint/test/build only (quality check)
Merge PR → Creates push to develop → Deploys to dev
```

---

### Mistake 3: "Pushed to main but no approval required"

**What you did**:
```bash
git push origin main
# Deployment ran immediately without approval
```

**Why this happened**:
```
Your main branch protection rules aren't configured
GitHub Settings → Branches → main → Protection rules
Need to set: "Require pull request reviews before merging"
```

**How to fix**:
1. Go to: Repository → Settings → Branches
2. Click "Add rule" or edit existing rule for main
3. Check: "Require pull request reviews before merging"
4. Now direct pushes to main are blocked
5. Must create PR → Get approval → Merge
6. Merge creates the push that triggers deployment with approval gate

---

### Mistake 4: "Manual QA deployment failed"

**Error**: "No workflow file found"

**Cause**: Workflow file not in main branch yet

**Solution**:
```bash
# Workflow file must be in default branch (main)
# Merge your workflow file to main first
# Then "Run workflow" button will appear
```

---

### Mistake 5: "Config not swapping correctly"

**Problem**: Deployed to dev but seeing production API URLs

**Cause**: Config swap step might have failed

**How to check**:
```bash
# Check workflow logs
# Look for "Swap environment configuration" step
# Verify it shows:
# "cp src/assets/config/environment.dev.json → environment.json"

# Also check: Is environment.dev.json correct?
cat src/assets/config/environment.dev.json
```

---

## Quick Reference Cheat Sheet

### When Does Workflow Run?

| Action | Workflow Runs? | Deployment? |
|--------|---------------|-------------|
| Push to `feature/*` | ❌ No | ❌ No |
| Create PR to `develop` | ✅ Yes | ❌ No (lint/test only) |
| Merge PR to `develop` | ✅ Yes | ✅ Yes (dev) |
| Push to `develop` | ✅ Yes | ✅ Yes (dev) |
| Push to `staging` | ✅ Yes | ✅ Yes (staging) |
| Push to `main` | ✅ Yes | ✅ Yes (prod, with approval) |
| Manual trigger (any branch) | ✅ Yes | ✅ Yes (to selected env) |

---

### Deployment Destinations

| Branch Pushed | Deploys To | Auto/Manual | Approval? |
|--------------|------------|-------------|-----------|
| `develop` | Development | Auto | No |
| `staging` | Staging | Auto | No |
| `main` | Production | Auto | **Yes** |
| ANY (manual) | Dev/QA/Staging/Prod | Manual | Only for prod |

---

### Environment URLs

```bash
# Development
http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com

# QA
http://angular-deploy-qa-shree-1767366539.s3-website-us-east-1.amazonaws.com

# Staging
http://angular-deploy-staging-shree-1767366539.s3-website-us-east-1.amazonaws.com

# Production (CloudFront - HTTPS)
https://d29lgch8cdh74n.cloudfront.net

# Production (S3 Direct - HTTP)
http://angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com
```

---

### Critical Workflow Checks

Each deployment job checks TWO conditions:

```yaml
# Development
if: github.ref == 'refs/heads/develop' && github.event_name == 'push'

# Staging
if: github.ref == 'refs/heads/staging' && github.event_name == 'push'

# Production
if: github.ref == 'refs/heads/main' && github.event_name == 'push'

# QA (different - no branch restriction)
if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'qa'
```

**Both conditions must be TRUE for deployment to run.**

---

### One Build, Many Deployments

```
Single Build Artifact
        ↓
        ├─ Swap environment.dev.json → Deploy to dev
        ├─ Swap environment.qa.json → Deploy to QA
        ├─ Swap environment.staging.json → Deploy to staging
        └─ Swap environment.production.json → Deploy to prod + CloudFront
```

**Key**: Same code everywhere, only config differs

---

### GitHub Actions Variables Reference

```yaml
# Branch name
github.ref
# Examples:
# - refs/heads/develop
# - refs/heads/staging
# - refs/heads/main
# - refs/heads/feature/new-feature

# Event type
github.event_name
# Values:
# - push
# - pull_request
# - workflow_dispatch

# Manual input (only for workflow_dispatch)
github.event.inputs.environment
# Values:
# - dev
# - qa
# - staging
# - prod
```

---

## Mental Model Summary

### The One-Sentence Summary

> **Git branches control WHAT code gets built, the workflow file controls WHERE it gets deployed, and the config swap controls HOW the app behaves.**

### The Five Rules

1. **Only three branches trigger automatic deployments**: `develop`, `staging`, `main`
2. **Feature branches never trigger the workflow** (not in the branch filter)
3. **Pull requests run tests but never deploy** (event_name check fails)
4. **Merging a PR creates a push event** (which triggers deployment)
5. **QA is special** - manual trigger only, accepts any branch

### The Three Gatekeepers

```
1. Branch Filter → Is this develop/staging/main?
2. Event Type → Is this a push (not PR)?
3. Branch Match → Does branch match deployment target?
```

All three must pass for deployment to run.

---

## Troubleshooting Guide

### "Run workflow" Button Missing

**Cause**: Workflow file not in main branch

**Solution**:
```bash
# Merge workflow file to main
# Create PR: develop → main
# After merge, button appears
```

---

### Deployment Not Running

**Check 1**: Is your branch in the trigger list?
```yaml
# Only these branches trigger on push:
push:
  branches:
    - develop
    - staging
    - main
```

**Check 2**: Is it a push event or PR event?
```
PR event → No deployment (correct)
Push event → Deployment should run
```

**Check 3**: Check workflow logs
```
GitHub → Actions → Click on workflow run
Look for skipped jobs
Read the "if" condition that caused the skip
```

---

### Wrong Environment Deployed

**Check**: Which branch did you push to?
```bash
# This deploys to dev:
git push origin develop

# This deploys to staging:
git push origin staging

# This deploys to prod (with approval):
git push origin main
```

---

**Last Updated**: 2026-01-03
**Version**: 1.0
**Related Documents**:
- [CICD-SETUP-GUIDE.md](CICD-SETUP-GUIDE.md)
- [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)
- [GITHUB-ACTIONS-MONITORING-GUIDE.md](GITHUB-ACTIONS-MONITORING-GUIDE.md)
