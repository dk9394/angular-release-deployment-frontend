# Deployment Options Guide

This project provides **three different deployment approaches**. Each serves a specific purpose in the development lifecycle.

---

## Quick Reference

| Method | Platform | Use Case | Command |
|--------|----------|----------|---------|
| **GitHub Actions** | All | Production deployments | `git push origin main` |
| **Bash Script** | Mac/Linux | Emergency manual deploys | `./deploy.sh prod` or `npm run deploy:prod` |
| **Node.js Script** | All | Cross-platform reference | `node deploy.mjs prod` or `npm run deploy:prod:node` |

---

## 1. GitHub Actions (Recommended)

**Status:** Coming in Phase 5 (CI/CD Implementation)

### When to Use
- All production deployments
- Automated deployments on push/merge
- When you want deployment history and audit trail
- Team collaboration (multiple developers)

### Advantages
- Automated testing before deployment
- Approval workflows for production
- Deployment history in GitHub UI
- No local AWS credentials needed
- Consistent deployment environment

### How to Use
```bash
# Deploy to production
git push origin main

# Deploy to staging (via PR merge)
git push origin staging
```

### Why This is Best for Production
1. **Consistency**: Every deployment follows the same steps
2. **Visibility**: Team can see what was deployed and when
3. **Safety**: Can add approval gates, tests, rollback mechanisms
4. **Audit**: Complete history of who deployed what and when

---

## 2. Bash Script (`deploy.sh`)

**Platform:** macOS, Linux, Git Bash on Windows

### When to Use
- Emergency hotfixes when CI/CD is down
- Local testing before pushing to CI/CD
- Debugging deployment issues locally
- Quick iterations during development

### Advantages
- Fast execution (no CI/CD overhead)
- Works offline (after initial build)
- Direct control over deployment process
- Useful for troubleshooting

### How to Use

**Direct execution:**
```bash
./deploy.sh dev       # Deploy to development
./deploy.sh qa        # Deploy to QA
./deploy.sh staging   # Deploy to staging
./deploy.sh prod      # Deploy to production
```

**Via npm scripts (easier to remember):**
```bash
npm run deploy:dev      # Deploy to development
npm run deploy:qa       # Deploy to QA
npm run deploy:staging  # Deploy to staging
npm run deploy:prod     # Deploy to production
```

**Get help:**
```bash
npm run deploy:help
```

### Limitations
- Requires AWS CLI installed and configured
- Doesn't work natively on Windows (needs Git Bash/WSL)
- No built-in approval process
- No deployment history

---

## 3. Node.js Script (`deploy.mjs`)

**Platform:** Windows, macOS, Linux (cross-platform)

### When to Use
- You're on Windows without Git Bash/WSL
- Learning how deployment works (educational reference)
- Prefer JavaScript over bash syntax
- Need cross-platform deployment script

### Advantages
- Works on any platform with Node.js
- Easier to understand than bash (for JS developers)
- Can be extended with npm packages
- Good reference implementation

### How to Use

**Direct execution:**
```bash
node deploy.mjs dev       # Deploy to development
node deploy.mjs qa        # Deploy to QA
node deploy.mjs staging   # Deploy to staging
node deploy.mjs prod      # Deploy to production
```

**Via npm scripts:**
```bash
npm run deploy:dev:node      # Deploy to development
npm run deploy:qa:node       # Deploy to QA
npm run deploy:staging:node  # Deploy to staging
npm run deploy:prod:node     # Deploy to production
```

### Limitations
- Still requires AWS CLI installed
- Slower than bash (for some operations)
- Not typically used in production environments

---

## Decision Tree

```
Need to deploy?
│
├─ Is this production deployment?
│  └─ YES → Use GitHub Actions (Phase 5)
│
├─ Is CI/CD working?
│  ├─ YES → Use GitHub Actions
│  └─ NO  → Emergency? Use deploy.sh
│
├─ Are you on Windows without Git Bash?
│  └─ YES → Use deploy.mjs
│
└─ Testing locally?
   └─ Use deploy.sh (faster)
```

---

## Detailed Comparison

### GitHub Actions (Production Standard)
```yaml
✅ Automated deployment on push
✅ Built-in approval workflows
✅ Deployment history & rollback
✅ No local AWS credentials needed
✅ Team collaboration support
✅ Integrated with PR reviews
❌ Requires internet connection
❌ Slower than local deployment
❌ Costs GitHub Actions minutes (free tier available)
```

### Bash Script (Emergency Backup)
```bash
✅ Fast execution
✅ Works offline (after build)
✅ Direct control
✅ Good for debugging
❌ Requires bash environment
❌ No approval workflow
❌ No deployment history
❌ Requires local AWS credentials
```

### Node.js Script (Cross-Platform Reference)
```javascript
✅ Cross-platform (Windows/Mac/Linux)
✅ Easy to understand (JavaScript)
✅ Can extend with npm packages
✅ Good learning resource
❌ Requires Node.js and AWS CLI
❌ Not industry standard for deployment
❌ Slower than bash
❌ Requires local AWS credentials
```

---

## Real-World Scenarios

### Scenario 1: Normal Development Day
**Situation:** You finished a feature and want to deploy to staging.

**Solution:**
```bash
git commit -m "feat: add user profile page"
git push origin staging
# GitHub Actions automatically deploys to staging
```

### Scenario 2: Emergency Production Hotfix
**Situation:** Production is down. GitHub Actions is experiencing an outage. You need to deploy NOW.

**Solution:**
```bash
# Fix the bug locally
git commit -m "fix: critical production bug"

# Deploy manually using bash script
npm run deploy:prod

# Push to GitHub after deployment
git push origin main
```

### Scenario 3: Testing Deployment Locally
**Situation:** You want to test if your build works before pushing to GitHub.

**Solution:**
```bash
# Test deployment to dev environment
npm run deploy:dev

# Verify it works, then push to GitHub
git push origin develop
```

### Scenario 4: Working on Windows
**Situation:** You're on Windows without Git Bash and need to deploy.

**Solution:**
```bash
# Use Node.js version
npm run deploy:dev:node
```

---

## Best Practices

### ✅ DO:
- Use GitHub Actions for all production deployments (after Phase 5)
- Keep deploy.sh for emergency situations
- Test deployments in dev/qa before production
- Document why you used manual deployment (in Slack/ticket)
- Review deployment logs before considering it successful

### ❌ DON'T:
- Bypass GitHub Actions for production unless emergency
- Deploy directly to production from your laptop regularly
- Share AWS credentials in Slack/email
- Deploy without testing in lower environments first
- Forget to invalidate CloudFront cache (production)

---

## Environment-Specific Recommendations

### Development (`dev`)
- Use any method (manual scripts are fine)
- Fast iteration is key
- Breaking things is okay

### QA (`qa`)
- Prefer GitHub Actions (simulate production workflow)
- Manual deployment acceptable for urgent fixes
- Test CI/CD pipeline here

### Staging (`staging`)
- Always use GitHub Actions
- This mirrors production exactly
- Never bypass the pipeline

### Production (`prod`)
- Always use GitHub Actions (after Phase 5)
- Manual deployment only for emergencies
- Requires approval (will be configured in Phase 5)
- Document all manual deployments

---

## Coming in Phase 5: GitHub Actions CI/CD

We will create automated deployment workflows that:

1. Run tests automatically
2. Build the application
3. Swap environment configurations
4. Deploy to S3
5. Invalidate CloudFront cache
6. Send deployment notifications

**Until then**, use the bash or Node.js scripts for all environments.

---

## Troubleshooting

### "AWS CLI not found"
**Solution:**
```bash
# Install AWS CLI
brew install awscli  # macOS
# Or download from: https://aws.amazon.com/cli/

# Configure credentials
aws configure
```

### "deploy.sh: Permission denied"
**Solution:**
```bash
chmod +x deploy.sh
```

### "deploy.sh doesn't work on Windows"
**Solution:**
Use the Node.js version:
```bash
npm run deploy:dev:node
```

### "Environment config not swapped"
**Solution:**
Check that the config file exists:
```bash
ls src/assets/config/environment.dev.json
```

---

## Learning Resources

- **Bash Scripting:** [Bash Guide for Beginners](https://www.tldp.org/LDP/Bash-Beginners-Guide/html/)
- **AWS CLI:** [Official Documentation](https://docs.aws.amazon.com/cli/)
- **GitHub Actions:** Coming in Phase 5 of this project
- **Node.js Scripting:** [Node.js Child Process Docs](https://nodejs.org/api/child_process.html)

---

## Quick Command Reference

```bash
# View all deployment options
npm run deploy:help

# Deploy to dev (bash)
npm run deploy:dev

# Deploy to dev (Node.js)
npm run deploy:dev:node

# Deploy to production (bash)
npm run deploy:prod

# Deploy to production (Node.js)
npm run deploy:prod:node

# Direct script execution
./deploy.sh prod
node deploy.mjs prod
```

---

**Next Phase:** Phase 5 - CI/CD with GitHub Actions (Automated Deployments)
