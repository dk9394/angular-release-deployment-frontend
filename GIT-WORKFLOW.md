# Git Flow Workflow - Multi-Environment Deployment

## Branch Strategy

```
main (production)           ─────●────────●──────────────●─────→
                                  ↑        ↑              ↑
                                  │        │              │
staging (stakeholder review) ────●────────●──────────────●─────→
                                  ↑        ↑              ↑
                                  │        │              │
develop (development)       ─●───●────●───●────●─────●───●─────→
                             │        │        │     │
                             │        │        │     │
feature/new-checkout    ────●────●───│        │     │
                                  └──►merge   │     │
feature/user-profile         ─────────────●───●────│
                                              └────►merge
hotfix/critical-bug               ──────────────────────●───→
                                                        └──►merge to main
```

## Branches Explained

### Permanent Branches (Never Deleted)

| Branch | Environment | URL | Purpose |
|--------|------------|-----|---------|
| `main` | Production | yourapp.com | Live production code |
| `staging` | Staging | staging.yourapp.com | Stakeholder review |
| `develop` | Development | dev.yourapp.com | Integration branch |

### Temporary Branches (Created & Deleted)

| Branch Pattern | Created From | Merged To | Purpose |
|---------------|--------------|-----------|---------|
| `feature/*` | develop | develop | New features |
| `release/*` | develop | staging → main | Release candidates (QA) |
| `hotfix/*` | main | main + develop | Emergency production fixes |

---

## Workflow: Feature Development → Production

### 1. Start New Feature

```bash
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication

# Work on feature
git add .
git commit -m "feat: add login component"
git push origin feature/user-authentication

# Create Pull Request: feature/user-authentication → develop
```

**CI/CD Action:** None (feature branches don't auto-deploy)

---

### 2. Merge to Develop (Development Environment)

```bash
# After PR approval
git checkout develop
git merge feature/user-authentication
git push origin develop

# Delete feature branch
git branch -d feature/user-authentication
```

**CI/CD Action:** ✅ Auto-deploy to **dev.yourapp.com**

**QA Action:** QA tests on dev environment

---

### 3. Create Release (QA Environment)

```bash
# Ready for QA? Create release branch
git checkout develop
git checkout -b release/v1.2.0

# Optional: Bug fixes on release branch
git commit -m "fix: resolve login timeout"

# Push release branch
git push origin release/v1.2.0
```

**CI/CD Action:** ✅ Auto-deploy to **qa.yourapp.com**

**QA Action:** Formal QA testing on qa environment

---

### 4. Merge to Staging (Stakeholder Review)

```bash
# QA approved? Merge to staging
git checkout staging
git merge release/v1.2.0
git push origin staging
```

**CI/CD Action:** ✅ Auto-deploy to **staging.yourapp.com**

**Stakeholder Action:** Business review and approval

---

### 5. Merge to Main (Production Release)

```bash
# Stakeholders approved? Merge to main
git checkout main
git merge release/v1.2.0
git tag v1.2.0
git push origin main --tags

# Merge back to develop (include any release fixes)
git checkout develop
git merge release/v1.2.0
git push origin develop

# Delete release branch
git branch -d release/v1.2.0
```

**CI/CD Action:** ✅ Auto-deploy to **yourapp.com** (PRODUCTION)

---

## Workflow: Hotfix (Emergency Production Fix)

### When Production is Broken!

```bash
# Create hotfix from main
git checkout main
git checkout -b hotfix/fix-payment-crash

# Fix the bug
git commit -m "fix: resolve payment processing crash"

# Merge to main (emergency deploy)
git checkout main
git merge hotfix/fix-payment-crash
git tag v1.2.1
git push origin main --tags

# Merge to develop (so fix is in next release)
git checkout develop
git merge hotfix/fix-payment-crash
git push origin develop

# Merge to staging (if active release)
git checkout staging
git merge hotfix/fix-payment-crash
git push origin staging

# Delete hotfix branch
git branch -d hotfix/fix-payment-crash
```

**CI/CD Action:** ✅ Auto-deploy to production immediately

---

## Branch → Environment Mapping

```
Git Branch          →  CI/CD Deploys To    →  Environment Config
──────────────────────────────────────────────────────────────────
develop             →  S3 dev bucket        →  environment.dev.json
release/*           →  S3 qa bucket         →  environment.qa.json
staging             →  S3 staging bucket    →  environment.staging.json
main                →  S3 prod bucket       →  environment.prod.json
```

---

## Complete Release Cycle Example

```
Day 1: Developer starts feature
  git checkout -b feature/new-checkout
  git commit -m "feat: add checkout flow"
  git push origin feature/new-checkout

Day 2: Code review + merge to develop
  PR approved → merge to develop
  CI/CD: Auto-deploy to dev.yourapp.com ✅

Day 3: QA finds bugs in dev
  Developer fixes on feature branch
  Merge to develop again
  CI/CD: Auto-deploy to dev.yourapp.com ✅

Day 5: Ready for formal QA
  git checkout -b release/v1.3.0
  CI/CD: Auto-deploy to qa.yourapp.com ✅
  QA tests for 2 days

Day 7: QA approved
  git checkout staging
  git merge release/v1.3.0
  CI/CD: Auto-deploy to staging.yourapp.com ✅
  Stakeholders review

Day 8: Stakeholders approved
  git checkout main
  git merge release/v1.3.0
  git tag v1.3.0
  CI/CD: Auto-deploy to yourapp.com ✅
  PRODUCTION RELEASE! 🎉

Day 9: Bug found in production!
  git checkout -b hotfix/checkout-crash
  git commit -m "fix: resolve checkout crash"
  Merge to main + develop + staging
  CI/CD: Auto-deploy to production immediately ✅
```

---

## Rules & Best Practices

### ✅ Do's

- ✅ Always create feature branches from `develop`
- ✅ Use conventional commit messages
- ✅ Create PRs for all merges to permanent branches
- ✅ Tag all production releases
- ✅ Merge hotfixes back to develop

### ❌ Don'ts

- ❌ Never commit directly to `main`
- ❌ Never commit directly to `staging`
- ❌ Never commit directly to `develop` (use feature branches)
- ❌ Never merge unreviewed code
- ❌ Never skip QA testing

---

## Environment Progression

```
Code must pass through ALL environments before production:

Local Development
      ↓
Development (dev.yourapp.com) - Auto-deploy from develop
      ↓
QA (qa.yourapp.com) - Auto-deploy from release/*
      ↓
Staging (staging.yourapp.com) - Auto-deploy from staging
      ↓
Production (yourapp.com) - Auto-deploy from main
```

**No skipping steps!** Every environment is a quality gate.

---

## Summary

- **develop** → Development environment (integration)
- **release/** → QA environment (formal testing)
- **staging** → Staging environment (stakeholder review)
- **main** → Production environment (live users)
- **feature/** → Local only (no auto-deploy)
- **hotfix/** → Emergency path to production

**Same code flows through all environments with different configurations!**
