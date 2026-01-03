# GitHub Repository Setup Guide

## Step 12: Create GitHub Repositories

### Frontend Repository

1. **Go to GitHub**: Navigate to [https://github.com/new](https://github.com/new)

2. **Repository Details**:
   - **Repository name**: `angular-release-deployment-frontend`
   - **Description**: `Industrial-grade Angular application with multi-environment deployment (dev, qa, staging, production)`
   - **Visibility**: Public (or Private based on your preference)
   - **⚠️ IMPORTANT**:
     - ❌ **DO NOT** initialize with README
     - ❌ **DO NOT** add .gitignore
     - ❌ **DO NOT** add license
     - (We already have a local repository with commits)

3. **After creation**, GitHub will show you commands. **IGNORE THOSE** and use the commands below instead.

### Backend Repository

1. **Go to GitHub**: Navigate to [https://github.com/new](https://github.com/new)

2. **Repository Details**:
   - **Repository name**: `angular-release-deployment-backend`
   - **Description**: `Node.js + Express + MongoDB backend API for Angular deployment learning project`
   - **Visibility**: Public (or Private based on your preference)
   - **⚠️ IMPORTANT**:
     - ❌ **DO NOT** initialize with README
     - ❌ **DO NOT** add .gitignore
     - ❌ **DO NOT** add license

---

## Commands to Run After Repository Creation

### Frontend Repository Setup

```bash
# Navigate to frontend directory
cd "/Users/shreeradhe/Documents/JIT Angular Learning/angular-release-deployment-frontend"

# Add remote (replace YOUR_USERNAME with your actual GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/angular-release-deployment-frontend.git

# Verify remote is added
git remote -v

# Push all branches to remote
git push -u origin main
git push -u origin develop
git push -u origin staging

# Verify all branches are pushed
git branch -a
```

### Backend Repository Setup

```bash
# Navigate to backend directory
cd "/Users/shreeradhe/Documents/JIT Angular Learning/angular-release-deployment-backend"

# Initialize Git repository
git init
git branch -M main

# Create .gitignore for Node.js
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment variables
.env
.env.local
.env.*.local
.env.dev
.env.qa
.env.staging
.env.production

# Build output
dist/
build/

# Logs
logs/
*.log
npm-debug.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# MongoDB
data/
EOF

# Add all files
git add .

# Create initial commit
git commit -m "feat: initial Node.js + Express + MongoDB backend setup

- Express server with TypeScript
- CORS configuration for multi-environment support
- MongoDB models and controllers
- Health check and product routes
- Environment-based configuration loader

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Add remote (replace YOUR_USERNAME with your actual GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/angular-release-deployment-backend.git

# Push to remote
git push -u origin main

# Verify push
git log --oneline
```

---

## Next Steps After Push

Once both repositories are pushed, we'll set up:
1. Branch protection rules (Step 13)
2. Pull request templates (Step 14)
3. GitHub Actions workflows (Phase 5)

---

## Verification Checklist

After running the commands above, verify:

- [ ] Frontend repository exists on GitHub
- [ ] Frontend has 3 branches: main, develop, staging
- [ ] Frontend has 2 commits visible on GitHub
- [ ] Backend repository exists on GitHub
- [ ] Backend has main branch with initial commit
- [ ] Both repositories show proper descriptions

---

## Troubleshooting

### If you get "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git
```

### If you need to use SSH instead of HTTPS
```bash
# Frontend
git remote set-url origin git@github.com:YOUR_USERNAME/angular-release-deployment-frontend.git

# Backend
git remote set-url origin git@github.com:YOUR_USERNAME/angular-release-deployment-backend.git
```

### If push is rejected
```bash
# Force push (safe because this is a new repository)
git push -u origin main --force
```
