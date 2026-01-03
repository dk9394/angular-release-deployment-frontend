# GitHub Branch Protection Rules Setup

## Why Branch Protection?

Branch protection rules enforce quality gates and prevent:
- Direct commits to important branches (main, staging, develop)
- Merging code without peer review
- Deploying untested code to production
- Accidental deletion of permanent branches
- Force pushes that rewrite history

In enterprise environments, **all code must go through pull requests** with mandatory reviews.

---

## Branch Protection Strategy

### Protection Level by Branch

| Branch | Protection Level | Why |
|--------|-----------------|-----|
| `main` | **Maximum** | Production code - highest risk |
| `staging` | **High** | Stakeholder demos - business critical |
| `develop` | **Medium** | Integration branch - prevents breaking changes |
| `feature/*` | **None** | Temporary branches - developer freedom |
| `release/*` | **High** | QA testing - needs stability |
| `hotfix/*` | **Medium** | Emergency fixes - balance speed & safety |

---

## Step-by-Step Configuration Guide

### Navigation to Branch Protection Settings

1. Go to your GitHub repository: `https://github.com/YOUR_USERNAME/angular-release-deployment-frontend`
2. Click on **Settings** tab (top navigation bar)
3. In the left sidebar, click **Branches** (under "Code and automation" section)
4. You'll see "Branch protection rules" section with "Add branch protection rule" button

---

## Rule 1: Protect `main` Branch (Production)

### Creating the Rule

1. Click **"Add branch protection rule"** button
2. In **"Branch name pattern"** field, type: `main`

### Settings to Configure:

#### Step 1: Require Pull Request Before Merging

3. ✅ Check **"Require a pull request before merging"**
   - A submenu will appear below
   - ✅ Check **"Require approvals"**
   - Set number to: **2**
   - ✅ Check **"Dismiss stale pull request approvals when new commits are pushed"**
   - ✅ (Optional) Check **"Require review from Code Owners"** if you have CODEOWNERS file

#### Step 2: Require Status Checks

4. ✅ Check **"Require status checks to pass before merging"**
   - ✅ Check **"Require branches to be up to date before merging"**
   - **Note**: Don't add specific status checks yet (we'll add in Phase 5 when CI/CD is set up)
   - Future checks: `lint`, `test`, `build`, `security-scan`

#### Step 3: Additional Protection Options

5. ✅ Check **"Require conversation resolution before merging"**
   - Ensures all PR comments are addressed before merge

6. ✅ Check **"Require linear history"**
   - Prevents merge commits, keeps history clean
   - Forces squash or rebase merges

7. ✅ Check **"Do not allow bypassing the above settings"**
   - Ensures no one can skip protection (including admins)

#### Step 4: Save the Rule

8. Scroll down to the bottom
9. Click **"Create"** button (or **"Save changes"** if editing existing rule)

---

## Rule 2: Protect `staging` Branch

### Creating the Rule

1. Click **"Add branch protection rule"** button again
2. In **"Branch name pattern"** field, type: `staging`

### Settings to Configure:

#### Step 1: Require Pull Request Before Merging

3. ✅ Check **"Require a pull request before merging"**
   - ✅ Check **"Require approvals"**
   - Set number to: **1**
   - ✅ Check **"Dismiss stale pull request approvals when new commits are pushed"**

#### Step 2: Require Status Checks

4. ✅ Check **"Require status checks to pass before merging"**
   - ✅ Check **"Require branches to be up to date before merging"**
   - **Note**: Status checks will be added in Phase 5

#### Step 3: Additional Protection Options

5. ✅ Check **"Require conversation resolution before merging"**

6. ✅ Check **"Require linear history"**

7. ✅ Check **"Do not allow bypassing the above settings"**

#### Step 4: Save the Rule

8. Click **"Create"** button

---

## Rule 3: Protect `develop` Branch

### Creating the Rule

1. Click **"Add branch protection rule"** button again
2. In **"Branch name pattern"** field, type: `develop`

### Settings to Configure:

#### Step 1: Require Pull Request Before Merging

3. ✅ Check **"Require a pull request before merging"**
   - ✅ Check **"Require approvals"**
   - Set number to: **1**
   - ✅ Check **"Dismiss stale pull request approvals when new commits are pushed"**

#### Step 2: Require Status Checks

4. ✅ Check **"Require status checks to pass before merging"**
   - ✅ Check **"Require branches to be up to date before merging"**
   - **Note**: Status checks will be added in Phase 5

#### Step 3: Additional Protection Options

5. ✅ Check **"Require conversation resolution before merging"**

6. ❌ **DO NOT** check **"Require linear history"**
   - Allow merge commits for feature integration
   - This gives developers flexibility when merging features

7. ✅ Check **"Do not allow bypassing the above settings"**

#### Step 4: Save the Rule

8. Click **"Create"** button

---

## Rule 4: Protect `release/*` Branches (Pattern Rule)

**Branch name pattern**: `release/*`

### Settings to Enable:

#### ✅ Require a pull request before merging
- **Require approvals**: 1

#### ✅ Require status checks to pass before merging
- **Status checks**:
  - `lint`
  - `test`
  - `build`

#### ✅ Require linear history

---

## Additional Repository Settings

### Configuring Pull Request and Merge Settings

#### Navigation

1. Still in **Settings**, click **General** in the left sidebar
2. Scroll down to **"Pull Requests"** section

#### Settings to Configure

3. ✅ Check **"Allow squash merging"**
   - In dropdown, select: **"Default to pull request title and description"**
   - Used for feature → develop merges

4. ✅ Check **"Allow rebase merging"**
   - Used for hotfixes and clean merges

5. ❌ (Optional) Uncheck **"Allow merge commits"**
   - Forces squash or rebase (cleaner history)
   - You can leave this checked if you want merge commits for develop

6. ✅ Check **"Automatically delete head branches"**
   - Cleans up merged feature branches automatically
   - Prevents branch clutter

#### Save Settings

7. Scroll down and click **"Save"** if there's a save button (some sections auto-save)

---

## Creating CODEOWNERS File (Optional but Recommended)

Create file: `.github/CODEOWNERS`

```
# Global owners
* @YOUR_USERNAME

# Frontend core
/src/app/core/ @senior-dev-1 @senior-dev-2

# Environment configurations (critical)
/src/assets/config/ @devops-lead @tech-lead

# CI/CD workflows
/.github/workflows/ @devops-lead

# Infrastructure
/docker/ @devops-lead
/nginx.conf @devops-lead
```

**Benefits**:
- Auto-assigns reviewers based on files changed
- Ensures domain experts review critical changes
- Enforces review from specific people for sensitive files

---

## Setting Up Status Checks

Status checks will be configured in **Phase 5: CI/CD Quality Gates**. For now, note that these checks will be required:

### Required Status Checks (Coming in Phase 5)

```yaml
# .github/workflows/ci.yml
name: CI Quality Gates

on:
  pull_request:
    branches: [main, staging, develop]

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run lint

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  build:
    name: Build Application
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit
```

Once these workflows are set up, GitHub will automatically require them to pass before allowing merges.

---

## Testing Branch Protection

### Test 1: Try Direct Commit to Main (Should Fail)

```bash
git checkout main
echo "test" >> README.md
git add .
git commit -m "test: direct commit"
git push origin main
```

**Expected Result**: ❌ Push rejected
```
remote: error: GH006: Protected branch update failed
```

### Test 2: Create Feature Branch and PR (Should Work)

```bash
git checkout develop
git checkout -b feature/test-branch-protection
echo "# Testing Branch Protection" > test.md
git add test.md
git commit -m "docs: add test file for branch protection"
git push origin feature/test-branch-protection
```

Then create PR on GitHub: `feature/test-branch-protection → develop`

**Expected Result**:
- ✅ PR created successfully
- ⚠️ Merge blocked until:
  - 1 approval received
  - Status checks pass (lint, test)
  - All conversations resolved

### Test 3: Verify Protection Rules

```bash
# Check protected branches
gh api repos/YOUR_USERNAME/angular-release-deployment-frontend/branches/main/protection

# Or via web: Settings > Branches > Branch protection rules
```

---

## Real-World Workflow After Protection

### Developer Workflow

```
Day 1: Start new feature
  git checkout develop
  git pull origin develop
  git checkout -b feature/JIRA-123-new-feature

  # Work on feature
  git commit -m "feat: implement new feature"
  git push origin feature/JIRA-123-new-feature

  # Create PR: feature/JIRA-123 → develop
  # Request review from 2 team members

Day 2: Address review comments
  git commit -m "refactor: apply code review feedback"
  git push origin feature/JIRA-123-new-feature

  # Reviews approved + status checks pass ✓
  # Merge PR (squash and merge)
  # Branch auto-deleted ✓

  # develop → Auto-deploy to dev.yourapp.com ✓
```

### Release Manager Workflow

```
Sprint End: Create release
  git checkout develop
  git checkout -b release/v1.2.0
  git push origin release/v1.2.0

  # QA testing on qa.yourapp.com

  # QA approved → Create PR: release/v1.2.0 → staging
  # 1 approval required
  # Merge → Auto-deploy to staging.yourapp.com

  # Stakeholder approval → Create PR: release/v1.2.0 → main
  # 2 approvals required
  # Merge → Auto-deploy to production ✓
```

### Hotfix Workflow (Emergency)

```
Production Bug!
  git checkout main
  git checkout -b hotfix/fix-critical-bug

  # Fix bug
  git commit -m "fix: resolve critical production bug"
  git push origin hotfix/fix-critical-bug

  # Create PR: hotfix → main
  # Get 2 approvals (expedited)
  # Merge → Production deploy

  # Also merge to develop and staging
```

---

## Summary

After setting up branch protection:

✅ **No direct commits to main/staging/develop**
✅ **All changes go through pull requests**
✅ **Mandatory code reviews**
✅ **Automated quality checks**
✅ **Clean Git history**
✅ **Safe production deployments**

This is how **99% of enterprise teams** work. Branch protection is the foundation of reliable software delivery.

---

## Next Steps

1. Apply these rules to **frontend repository**
2. Apply same rules to **backend repository**
3. Create test PR to verify protection works
4. In Phase 5, we'll add GitHub Actions workflows that run as required status checks

---

## Quick Setup Checklist

### Frontend Repository
- [ ] Protect `main` branch (2 approvals, linear history)
- [ ] Protect `staging` branch (1 approval, linear history)
- [ ] Protect `develop` branch (1 approval)
- [ ] Protect `release/*` pattern (1 approval)
- [ ] Enable auto-delete of merged branches
- [ ] Set default merge method to squash

### Backend Repository
- [ ] Protect `main` branch (2 approvals, linear history)
- [ ] Enable auto-delete of merged branches
- [ ] Set default merge method to squash

---

**Ready to configure?** Go to your GitHub repository settings and apply these rules!
