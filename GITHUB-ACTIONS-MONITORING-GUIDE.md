# GitHub Actions Deployment Monitoring Guide

## How to Check Deployment Summaries in GitHub Actions

This guide shows you how to monitor your CI/CD deployments, view logs, check deployment summaries, and troubleshoot issues.

---

## Table of Contents

1. [Accessing GitHub Actions](#accessing-github-actions)
2. [Understanding the Workflow Dashboard](#understanding-the-workflow-dashboard)
3. [Viewing Deployment Details](#viewing-deployment-details)
4. [Reading Deployment Summaries](#reading-deployment-summaries)
5. [Monitoring Live Deployments](#monitoring-live-deployments)
6. [Checking Deployment History](#checking-deployment-history)
7. [Troubleshooting Failed Deployments](#troubleshooting-failed-deployments)
8. [Using GitHub CLI for Monitoring](#using-github-cli-for-monitoring)

---

## Accessing GitHub Actions

### Method 1: Via GitHub Web UI

1. Navigate to your repository on GitHub
2. Click the **"Actions"** tab at the top

```
https://github.com/YOUR_USERNAME/angular-release-deployment-frontend/actions
```

### Method 2: Via Direct URL

```
https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

### Method 3: Via GitHub CLI

```bash
gh run list
```

---

## Understanding the Workflow Dashboard

### What You'll See:

```
┌─────────────────────────────────────────────────────────────┐
│ All workflows                                               │
├─────────────────────────────────────────────────────────────┤
│ ○ Deploy to AWS S3                                          │
│   ├─ feat: add new feature                                  │
│   │  ✅ #42 · develop · 2m 34s                              │
│   ├─ fix: production hotfix                                 │
│   │  ✅ #41 · main · 3m 12s · Waiting for approval          │
│   └─ chore: update dependencies                             │
│      ❌ #40 · develop · 1m 45s                              │
└─────────────────────────────────────────────────────────────┘
```

### Status Indicators:

| Icon | Status | Meaning |
|------|--------|---------|
| ✅ | Success | Deployment completed successfully |
| ❌ | Failure | Deployment failed |
| 🔵 | In Progress | Currently running |
| ⏸️ | Waiting | Pending approval (production) |
| ⚪ | Queued | Waiting to start |
| 🔴 | Cancelled | Manually stopped |

---

## Viewing Deployment Details

### Step 1: Click on a Workflow Run

Click any workflow run to see detailed information:

```
Deploy to AWS S3#42
✅ Completed in 2m 34s

Triggered by: push
Branch: develop
Commit: abc1234 - "feat: add user profile page"
Author: Your Name
```

### Step 2: View Job Details

You'll see all jobs in the workflow:

```
Jobs
├─ ✅ Lint & Format Check (15s)
├─ ✅ Unit Tests (28s)
├─ ✅ Build Angular App (1m 12s)
├─ ✅ Deploy to Development (38s)
└─ ✅ Send Deployment Notification (3s)
```

### Step 3: Expand Individual Jobs

Click any job to see step-by-step execution:

```
Deploy to Development

  ✅ Set up job (2s)
  ✅ Checkout code (4s)
  ✅ Download build artifacts (6s)
  ✅ Swap environment configuration (1s)
  ✅ Configure AWS credentials (2s)
  ✅ Deploy to S3 (18s)
  ✅ Deployment summary (1s)
  ✅ Post Configure AWS credentials (1s)
  ✅ Post Checkout code (1s)
  ✅ Complete job (2s)
```

---

## Reading Deployment Summaries

### Where to Find the Summary

1. Navigate to the specific workflow run
2. Click on the **"Deploy to [Environment]"** job
3. Scroll to the **"Deployment summary"** step
4. Click to expand the step

### What the Summary Shows

```bash
Deployment summary

✅ Development deployment successful!
🌐 URL: http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com
```

**For Production:**

```bash
Deployment summary

✅ Production deployment successful!
🌐 CloudFront URL: https://d29lgch8cdh74n.cloudfront.net (CloudFront - Recommended)
🌐 S3 Direct URL: http://angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com (S3 Direct)
⏱️  CloudFront cache invalidated - fresh content available in 1-2 minutes
```

### Copying the Deployment URL

1. Expand the "Deployment summary" step
2. Click and drag to select the URL
3. Copy it (Cmd+C or Ctrl+C)
4. Open in browser to verify deployment

---

## Monitoring Live Deployments

### Real-Time Monitoring

While a deployment is running:

1. Navigate to Actions tab
2. Click the in-progress workflow (blue dot 🔵)
3. Click the running job
4. Watch logs update in real-time

**You'll see:**

```
Run aws s3 sync dist/angular-release-deployment-frontend/browser \
  s3://angular-deploy-dev-shree-1767366539 --delete

upload: dist/browser/index.html to s3://angular-deploy-dev-shree-1767366539/index.html
upload: dist/browser/main-E7O2MXZP.js to s3://angular-deploy-dev-shree-1767366539/main-E7O2MXZP.js
upload: dist/browser/styles-ABCD1234.css to s3://angular-deploy-dev-shree-1767366539/styles-ABCD1234.css
...
```

### Auto-Refresh

GitHub Actions automatically refreshes logs every few seconds. You can:
- Watch progress in real-time
- See exactly which files are being uploaded
- Monitor for errors as they happen

---

## Checking Deployment History

### View All Deployments

**Via Web UI:**

```
Actions Tab → Deploy to AWS S3 (left sidebar) → View all workflow runs
```

**Via GitHub CLI:**

```bash
# List last 10 workflow runs
gh run list --workflow=deploy-s3.yml --limit 10

# View specific run
gh run view 1234567890

# View with web browser
gh run view 1234567890 --web
```

### Filter by Environment

Look for runs that deployed to specific environments:

```
# Development deployments (from develop branch)
Actions → Filter by branch: develop

# Staging deployments (from staging branch)
Actions → Filter by branch: staging

# Production deployments (from main branch)
Actions → Filter by branch: main
```

### View Deployment Timeline

```
Timeline View:

Jan 3, 2026 10:45 AM - ✅ Deploy to production (#45)
Jan 3, 2026 10:30 AM - ✅ Deploy to staging (#44)
Jan 3, 2026 10:15 AM - ❌ Deploy to development (#43) - Failed
Jan 3, 2026 10:00 AM - ✅ Deploy to development (#42)
```

---

## Troubleshooting Failed Deployments

### Step 1: Identify the Failed Job

Click on the failed run (red ❌):

```
❌ Deploy to AWS S3 #43
Failed in 1m 45s
```

### Step 2: Find the Failing Step

Click on the job to see which step failed:

```
Deploy to Development

  ✅ Set up job (2s)
  ✅ Checkout code (4s)
  ✅ Download build artifacts (6s)
  ✅ Swap environment configuration (1s)
  ❌ Configure AWS credentials (0s)  ← FAILED HERE
  ⚪ Deploy to S3 (skipped)
  ⚪ Deployment summary (skipped)
```

### Step 3: Read the Error Message

Expand the failed step to see the error:

```
Run aws-actions/configure-aws-credentials@v4
Error: Credentials could not be loaded
Error: Please check that your secrets are configured correctly
```

### Common Errors and Solutions

#### Error: "Credentials could not be loaded"

**Cause:** AWS secrets not configured

**Solution:**
```
1. Go to Settings → Secrets and variables → Actions
2. Verify AWS_ACCESS_KEY_ID exists
3. Verify AWS_SECRET_ACCESS_KEY exists
4. Check for typos in secret names
```

#### Error: "The bucket does not exist"

**Cause:** S3 bucket not created or wrong UNIQUE_ID

**Solution:**
```bash
# Verify UNIQUE_ID secret matches your bucket names
aws s3 ls | grep angular-deploy

# Expected output:
# angular-deploy-dev-shree-1767366539
# angular-deploy-qa-shree-1767366539
# angular-deploy-staging-shree-1767366539
# angular-deploy-prod-shree-1767366539
```

#### Error: "No such file or directory"

**Cause:** Build artifacts not found

**Solution:**
Check the "Build Angular App" job completed successfully before deployment job ran.

#### Error: "Access Denied" on S3 sync

**Cause:** IAM user lacks S3 permissions

**Solution:**
```
1. AWS Console → IAM → Users → angular-deployment-user
2. Verify AmazonS3FullAccess policy is attached
3. Or add inline policy for specific buckets
```

### Step 4: Re-run Failed Workflow

After fixing the issue:

1. Click "Re-run failed jobs" button (top right)
2. Or "Re-run all jobs" to start fresh
3. Monitor the new run

---

## Using GitHub CLI for Monitoring

### Install GitHub CLI

```bash
# macOS
brew install gh

# Verify
gh --version
```

### Authentication

```bash
gh auth login
```

### Useful Commands

#### List Recent Runs

```bash
# Last 10 runs
gh run list --limit 10

# Filter by status
gh run list --status failure
gh run list --status success
gh run list --status in_progress
```

#### View Specific Run

```bash
# Get run ID from list, then view details
gh run view 1234567890

# View in browser
gh run view 1234567890 --web

# View logs
gh run view 1234567890 --log
```

#### Watch Live Deployment

```bash
# Watch a running workflow
gh run watch

# View logs as they happen
gh run view --log-failed
```

#### Download Logs

```bash
# Download logs for later analysis
gh run download 1234567890

# This creates a folder with all job logs
```

---

## Deployment Summary Checklist

After each deployment, verify:

### ✅ Development Deployment

- [ ] Workflow completed successfully (green checkmark)
- [ ] All jobs passed (Lint, Test, Build, Deploy)
- [ ] Deployment summary shows correct URL
- [ ] URL is accessible in browser
- [ ] Environment config loaded (check browser console)

### ✅ Staging Deployment

- [ ] Workflow completed successfully
- [ ] All tests passed before deployment
- [ ] Staging URL accessible
- [ ] Features work as expected

### ✅ Production Deployment

- [ ] Approval was requested and granted
- [ ] All quality gates passed
- [ ] CloudFront invalidation completed
- [ ] Both CloudFront and S3 URLs accessible
- [ ] Production config loaded correctly
- [ ] No errors in browser console

---

## Best Practices for Monitoring

### 1. Check Deployments Immediately

After pushing code:
```bash
# Quick check
gh run list --limit 1

# Watch live
gh run watch
```

### 2. Set Up Notifications

**GitHub Web UI:**
```
Repository → Settings → Notifications
→ Enable "Actions" notifications
```

**GitHub CLI:**
```bash
# Watch specific workflow
gh run watch --exit-status
```

### 3. Review Failed Deployments

Don't ignore failed deployments:
1. Check error logs within 5 minutes
2. Fix issues immediately
3. Re-run or push fix
4. Document recurring issues

### 4. Monitor Deployment Duration

Track deployment times:
```
Normal timing:
- Lint: ~15s
- Test: ~30s
- Build: ~1-2 minutes
- Deploy to S3: ~20-40s
- Total: ~2-3 minutes

If significantly slower:
- Check GitHub Actions status
- Check AWS S3 performance
- Review build optimization
```

### 5. Verify Each Environment

After deployment, test:
```bash
# Development
open http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com

# Staging
open http://angular-deploy-staging-shree-1767366539.s3-website-us-east-1.amazonaws.com

# Production (CloudFront)
open https://d29lgch8cdh74n.cloudfront.net
```

---

## Deployment Summary Examples

### Successful Development Deployment

```
✅ Deploy to AWS S3 #42
Completed in 2m 34s

Jobs:
  ✅ Lint & Format Check (15s)
  ✅ Unit Tests (28s)
  ✅ Build Angular App (1m 12s)
  ✅ Deploy to Development (38s)
  ✅ Send Deployment Notification (3s)

Deployment Summary:
  ✅ Development deployment successful!
  🌐 URL: http://angular-deploy-dev-shree-1767366539.s3-website-us-east-1.amazonaws.com
```

### Successful Production Deployment with Approval

```
✅ Deploy to AWS S3 #45
Completed in 3m 45s (including 2m approval wait)

Jobs:
  ✅ Lint & Format Check (15s)
  ✅ Unit Tests (28s)
  ✅ Build Angular App (1m 15s)
  ⏸️ Deploy to Production (waiting for approval - 2m)
  ✅ Deploy to Production (52s)
    ├─ Deployment to S3 (35s)
    ├─ CloudFront invalidation (12s)
    └─ Deployment summary (1s)

Deployment Summary:
  ✅ Production deployment successful!
  🌐 CloudFront URL: https://d29lgch8cdh74n.cloudfront.net
  🌐 S3 Direct URL: http://angular-deploy-prod-shree-1767366539.s3-website-us-east-1.amazonaws.com
  ⏱️  CloudFront cache invalidated - fresh content available in 1-2 minutes

Approved by: @YourUsername
```

### Failed Deployment

```
❌ Deploy to AWS S3 #43
Failed in 1m 45s

Jobs:
  ✅ Lint & Format Check (15s)
  ✅ Unit Tests (28s)
  ✅ Build Angular App (1m 12s)
  ❌ Deploy to Development (0s)
     Error: Credentials could not be loaded

Error Details:
  Step: Configure AWS credentials
  Error: Unable to locate credentials
  Solution: Check GitHub Secrets configuration

Actions:
  • Re-run jobs
  • View raw logs
  • Download logs
```

---

## Quick Reference Card

```bash
# ═══════════════════════════════════════════════════════
# GitHub Actions Monitoring - Quick Reference
# ═══════════════════════════════════════════════════════

# View all workflow runs
gh run list

# Watch current deployment
gh run watch

# View specific run
gh run view <run-id>

# View in browser
gh run view <run-id> --web

# View logs
gh run view <run-id> --log

# Download logs
gh run download <run-id>

# List failed runs
gh run list --status failure

# Re-run failed jobs (via web UI)
# Actions → Click failed run → Re-run failed jobs

# Cancel running workflow
gh run cancel <run-id>

# View deployment URL (after success)
# Actions → Click run → Deploy job → Deployment summary step
```

---

## Next Steps

After understanding how to monitor deployments:

1. ✅ Configure GitHub Secrets (if not done)
2. ✅ Test your first deployment
3. ✅ Monitor the deployment using this guide
4. ✅ Verify the deployed application works
5. ✅ Test production approval workflow
6. ✅ Set up deployment notifications

---

**Last Updated:** 2026-01-03
**Phase:** Phase 5 - CI/CD for Serverless
**Related Guides:** [CICD-SETUP-GUIDE.md](CICD-SETUP-GUIDE.md), [DEPLOYMENT-OPTIONS.md](DEPLOYMENT-OPTIONS.md)
