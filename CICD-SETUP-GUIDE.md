# CI/CD Setup Guide - GitHub Actions for AWS S3

## Overview

This guide walks you through setting up automated CI/CD pipelines for deploying your Angular application to AWS S3 across multiple environments (dev, qa, staging, production).

**What This Achieves:**
- Automated deployments on git push
- Linting and testing before deployment
- Environment-specific configurations
- CloudFront cache invalidation (production)
- Manual approval gates for production
- Deployment history and audit trail

---

## Prerequisites

Before setting up CI/CD, ensure you have:

1. ✅ GitHub repository created and connected
2. ✅ AWS account with CLI configured
3. ✅ S3 buckets created for all environments
4. ✅ CloudFront distribution created (production)
5. ✅ Manual deployment working (via deploy.sh)

---

## Phase 5: CI/CD Implementation

### Step 1: Configure GitHub Repository Environments

GitHub Environments provide protection rules and secrets scoping.

**1.1 Navigate to Repository Settings:**
```
GitHub Repository → Settings → Environments
```

**1.2 Create Four Environments:**

Click "New environment" and create each of these:

| Environment Name | Protection Rules | Purpose |
|-----------------|------------------|---------|
| `development` | None | Auto-deploy from develop branch |
| `qa` | None | Manual trigger only |
| `staging` | None | Auto-deploy from staging branch |
| `production` | ✅ Required reviewers | Manual approval before deploy |

**1.3 Configure Production Protection:**

For the `production` environment:
- ✅ Check "Required reviewers"
- Add yourself (or team members) as reviewers
- This creates a manual approval gate

**Why This Matters:**
- Prevents accidental production deployments
- Requires explicit approval before prod changes
- Creates audit trail of who approved what

---

### Step 2: Configure GitHub Secrets

Secrets store sensitive credentials securely and make them available to workflows.

**2.1 Navigate to Secrets Settings:**
```
GitHub Repository → Settings → Secrets and variables → Actions
```

**2.2 Create Repository Secrets:**

Click "New repository secret" and add each of these:

#### Secret 1: AWS_ACCESS_KEY_ID
```
Name: AWS_ACCESS_KEY_ID
Secret: [Your AWS Access Key ID]
```

**How to get this value:**
```bash
# If you saved it during IAM user creation, use that
# Otherwise, create a new access key:
# AWS Console → IAM → Users → angular-deployment-user
# → Security credentials → Create access key
```

#### Secret 2: AWS_SECRET_ACCESS_KEY
```
Name: AWS_SECRET_ACCESS_KEY
Secret: [Your AWS Secret Access Key]
```

**Security Note:** This is shown only once when created. If lost, create new access keys.

#### Secret 3: UNIQUE_ID
```
Name: UNIQUE_ID
Secret: shree-1767366539
```

**From your `.env.aws` file:**
```bash
cat .env.aws | grep UNIQUE_ID
```

#### Secret 4: CLOUDFRONT_DISTRIBUTION_ID
```
Name: CLOUDFRONT_DISTRIBUTION_ID
Secret: E1QKKABZX5LKQQ
```

**From your `.env.aws` file:**
```bash
cat .env.aws | grep CLOUDFRONT_DISTRIBUTION_ID
```

#### Secret 5: CLOUDFRONT_DOMAIN
```
Name: CLOUDFRONT_DOMAIN
Secret: d29lgch8cdh74n.cloudfront.net
```

**From your `.env.aws` file:**
```bash
cat .env.aws | grep CLOUDFRONT_DOMAIN
```

**2.3 Verify All Secrets Created:**

You should now see 5 repository secrets:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ UNIQUE_ID
- ✅ CLOUDFRONT_DISTRIBUTION_ID
- ✅ CLOUDFRONT_DOMAIN

---

### Step 3: Understanding the Workflow

The workflow file (`.github/workflows/deploy-s3.yml`) defines the CI/CD pipeline.

**3.1 Workflow Triggers:**

| Trigger | When | Action |
|---------|------|--------|
| Push to `develop` | Auto | Deploy to development |
| Push to `staging` | Auto | Deploy to staging |
| Push to `main` | Auto | Deploy to production (after approval) |
| Manual trigger | Manual | Deploy to any environment |
| Pull request | Auto | Run tests only (no deployment) |

**3.2 Workflow Jobs:**

```
1. Lint & Format Check
   └─ Runs ESLint and Prettier
   └─ Blocks deployment if code quality issues

2. Unit Tests
   └─ Runs all unit tests
   └─ Blocks deployment if tests fail

3. Build
   └─ Builds Angular app for production
   └─ Uploads build artifacts for deployment jobs

4. Deploy to Dev (if push to develop)
   └─ Downloads build artifacts
   └─ Swaps environment.dev.json
   └─ Syncs to S3 dev bucket

5. Deploy to QA (manual trigger only)
   └─ Same steps as dev, but for QA environment

6. Deploy to Staging (if push to staging)
   └─ Same steps as dev, but for staging environment

7. Deploy to Production (if push to main)
   └─ Requires manual approval
   └─ Downloads build artifacts
   └─ Swaps environment.production.json
   └─ Syncs to S3 prod bucket
   └─ Invalidates CloudFront cache

8. Notify
   └─ Send deployment notifications (optional)
```

**3.3 Workflow Environment Variables:**

```yaml
NODE_VERSION: '20.x'    # Node.js version for builds
AWS_REGION: 'us-east-1' # AWS region for all services
```

---

### Step 4: Test the CI/CD Pipeline

**4.1 Test Development Deployment:**

```bash
# Make a small change
echo "// CI/CD test" >> src/app/app.component.ts

# Commit and push to develop
git add .
git commit -m "test: CI/CD pipeline test"
git push origin develop
```

**4.2 Monitor Workflow Execution:**

```
GitHub Repository → Actions tab
```

You should see:
- ✅ Workflow running
- ✅ Lint job passes
- ✅ Test job passes
- ✅ Build job passes
- ✅ Deploy-dev job runs
- ✅ Green checkmark when complete

**4.3 Verify Deployment:**

Visit: `http://angular-deploy-dev-{your-unique-id}.s3-website-us-east-1.amazonaws.com`

Your changes should be live!

---

### Step 5: Test Production Deployment with Approval

**5.1 Merge to Main Branch:**

```bash
# Switch to main
git checkout main

# Merge from develop (or create a PR and merge)
git merge develop

# Push to main
git push origin main
```

**5.2 Approve Deployment:**

```
GitHub Repository → Actions → Click on the running workflow
```

You should see:
- ✅ Lint, test, build jobs complete
- ⏸️ Deploy-prod job waiting for approval
- 🔔 Yellow banner: "Review pending"

Click **"Review deployments"** → Select **"production"** → Click **"Approve and deploy"**

**5.3 Watch Production Deployment:**

After approval:
- ✅ Deploy-prod job runs
- ✅ Files sync to S3
- ✅ CloudFront cache invalidated
- ✅ Deployment complete

**5.4 Verify Production:**

Visit: `https://{your-cloudfront-domain}`

Changes should be live within 1-2 minutes (CloudFront propagation time).

---

### Step 6: Manual Deployment to QA

**6.1 Trigger Manual Deployment:**

```
GitHub Repository → Actions → deploy-s3 workflow
→ Click "Run workflow" dropdown
```

**6.2 Select Environment:**

```
Branch: develop (or any branch)
Environment: qa
```

Click **"Run workflow"**

**6.3 Monitor Execution:**

The workflow will:
- ✅ Run lint, test, build
- ✅ Deploy to QA environment only

---

## Deployment Workflows

### Development Workflow (Auto-Deploy)

```bash
# 1. Create feature branch
git checkout -b feature/new-feature develop

# 2. Make changes
# ... code changes ...

# 3. Commit
git commit -m "feat: add new feature"

# 4. Push to feature branch
git push origin feature/new-feature

# 5. Create PR to develop
# GitHub UI: Create Pull Request

# 6. After PR approval, merge to develop
# Merging triggers automatic deployment to dev
```

**Result:** Changes automatically deployed to development environment

---

### Staging Workflow (Auto-Deploy)

```bash
# 1. When dev testing is complete, merge to staging
git checkout staging
git merge develop
git push origin staging
```

**Result:** Changes automatically deployed to staging environment

---

### Production Workflow (Manual Approval)

```bash
# 1. When staging testing is complete, merge to main
git checkout main
git merge staging
git push origin main
```

**What happens:**
1. GitHub Actions workflow starts
2. Runs lint, test, build
3. **Pauses** and requests approval
4. Team lead reviews and approves
5. Deployment proceeds
6. CloudFront cache invalidated
7. Production updated

---

## Troubleshooting

### Issue: Workflow fails on "Configure AWS credentials"

**Error:**
```
Error: Credentials could not be loaded
```

**Solution:**
- Verify GitHub Secrets are set correctly
- Check secret names match exactly (case-sensitive)
- Ensure AWS access keys are valid

**Verify:**
```bash
# Test locally
aws sts get-caller-identity
```

---

### Issue: Workflow fails on "Deploy to S3"

**Error:**
```
fatal error: Unable to locate credentials
```

**Solution:**
- Check AWS secrets are repository-level secrets (not environment-level)
- Ensure IAM user has S3 permissions

**Test manually:**
```bash
./deploy.sh dev
```

If manual deployment works, the issue is with GitHub Secrets configuration.

---

### Issue: CloudFront invalidation fails

**Error:**
```
An error occurred (NoSuchDistribution) when calling CreateInvalidation
```

**Solution:**
- Verify `CLOUDFRONT_DISTRIBUTION_ID` secret is correct
- Check distribution exists: `aws cloudfront list-distributions`

---

### Issue: Production deployment doesn't require approval

**Problem:**
Production environment doesn't show "Review pending" status.

**Solution:**
1. Go to Settings → Environments → production
2. Check "Required reviewers"
3. Add at least one reviewer
4. Save protection rules

---

### Issue: Tests fail in CI but pass locally

**Common causes:**
- Different Node.js versions
- Missing environment variables
- Timezone differences

**Solution:**
Match local environment to CI:
```json
{
  "engines": {
    "node": "20.x",
    "npm": "10.x"
  }
}
```

---

## Best Practices

### ✅ DO:

1. **Always test in dev first**
   - Push to develop → test in dev → then promote

2. **Use pull requests for develop/staging/main**
   - Enables code review before deployment

3. **Review deployment logs**
   - Check Actions tab after each deployment

4. **Keep secrets updated**
   - Rotate AWS keys quarterly

5. **Document deployment decisions**
   - Use PR descriptions to explain why deploying

### ❌ DON'T:

1. **Don't skip approval for production**
   - Always require manual review

2. **Don't commit .env.aws to git**
   - Secrets belong in GitHub Secrets only

3. **Don't force push to main/staging/develop**
   - Breaks deployment history

4. **Don't deploy without testing**
   - Use lower environments first

5. **Don't share AWS credentials**
   - Use IAM roles or temporary credentials

---

## CI/CD vs Manual Deployment

### When to Use CI/CD (Recommended)

✅ Normal feature development
✅ Bug fixes
✅ Regular releases
✅ Team collaboration
✅ Production deployments

**Advantages:**
- Automated testing
- Consistent deployments
- Approval workflows
- Deployment history
- Team visibility

### When to Use Manual Deployment (Emergency Only)

⚠️ CI/CD is down
⚠️ Critical hotfix needed NOW
⚠️ Testing deployment script changes
⚠️ Debugging deployment issues

**Commands:**
```bash
# Emergency production deployment
./deploy.sh prod

# Or using npm
npm run deploy:prod
```

**After manual deployment:**
- Document why it was necessary
- Create follow-up PR to sync git history

---

## Monitoring Deployments

### GitHub Actions Dashboard

```
Repository → Actions tab
```

**What you see:**
- ✅ Successful deployments (green)
- ❌ Failed deployments (red)
- ⏸️ Pending approvals (yellow)
- 🔵 In progress (blue)

### CloudWatch (AWS)

```
AWS Console → CloudWatch → Logs
```

**What you see:**
- S3 access logs
- CloudFront request logs
- Error patterns

### S3 Bucket Monitoring

```bash
# Check last deployment time
aws s3 ls s3://angular-deploy-prod-${UNIQUE_ID} --recursive | tail -10

# Check bucket size
aws s3 ls s3://angular-deploy-prod-${UNIQUE_ID} --recursive --summarize
```

---

## Cost Analysis

### GitHub Actions (Free Tier)

- 2,000 minutes/month (free)
- Each deployment: ~5 minutes
- **Result:** 400 deployments/month free

### AWS Costs

**S3:**
- Storage: ~$0.023/GB/month
- Requests: ~$0.0004/1,000 requests
- Data transfer: Free to CloudFront

**CloudFront:**
- 50GB data transfer/month (free tier)
- 2M HTTP requests/month (free tier)
- Invalidations: First 1,000 paths/month FREE

**Estimated Total:** $0-5/month for low-traffic apps

---

## Advanced Configuration

### Adding Environment-Specific Secrets

For different AWS accounts per environment:

```yaml
# In workflow file
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets[format('AWS_ACCESS_KEY_ID_{0}', env.ENVIRONMENT)] }}
    aws-secret-access-key: ${{ secrets[format('AWS_SECRET_ACCESS_KEY_{0}', env.ENVIRONMENT)] }}
```

**GitHub Secrets:**
- AWS_ACCESS_KEY_ID_DEV
- AWS_ACCESS_KEY_ID_STAGING
- AWS_ACCESS_KEY_ID_PROD

### Adding Slack Notifications

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Deployment to ${{ github.ref }} completed! 🚀"
      }
```

### Adding Deployment Tags

```yaml
- name: Tag deployment
  run: |
    git tag -a "deploy-prod-$(date +%Y%m%d-%H%M%S)" -m "Production deployment"
    git push origin --tags
```

---

## Security Checklist

- ✅ AWS credentials stored in GitHub Secrets (not code)
- ✅ IAM user has minimal permissions (S3, CloudFront only)
- ✅ Production requires manual approval
- ✅ .env.aws in .gitignore
- ✅ Access keys rotated quarterly
- ✅ CloudWatch logs enabled
- ✅ S3 bucket policies restrict to GetObject only
- ✅ CloudFront uses HTTPS

---

## Next Steps

After CI/CD is working:

1. **Phase 6:** Add Docker containerization
2. **Phase 7:** Implement versioning automation
3. **Phase 8:** Add blue-green deployments
4. **Phase 9:** Cross-repo integration testing

---

## Quick Command Reference

```bash
# Test workflow locally (using act)
act -j lint

# Validate workflow syntax
yamllint .github/workflows/deploy-s3.yml

# View workflow runs
gh run list

# View specific run logs
gh run view <run-id>

# Re-run failed workflow
gh run rerun <run-id>

# List environments
gh api repos/:owner/:repo/environments | jq '.environments[].name'

# List secrets
gh secret list
```

---

## Support

**Workflow Issues:**
- Check Actions tab for detailed logs
- Review step-by-step output
- Check GitHub Secrets configuration

**AWS Issues:**
- Test manual deployment first: `./deploy.sh dev`
- Check AWS CLI configuration: `aws sts get-caller-identity`
- Verify IAM permissions

**Questions:**
- Review this guide
- Check [DEPLOYMENT-OPTIONS.md](DEPLOYMENT-OPTIONS.md)
- Check [AWS-KNOWLEDGE-GUIDE.md](AWS-KNOWLEDGE-GUIDE.md)

---

**Last Updated:** 2026-01-03
**Phase:** Phase 5 - CI/CD for Serverless (S3 + CloudFront)
**Status:** Ready for implementation
