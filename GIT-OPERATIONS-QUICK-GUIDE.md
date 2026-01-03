# Quick Git Operations Guide

## Essential Commands for This Project

### 1. Merge (Combining Branches)
```bash
# Merge feature into develop
git checkout develop
git merge feature/my-feature
git push origin develop
```

### 2. Rebase (Clean History)
```bash
# Rebase feature on latest develop
git checkout feature/my-feature
git rebase develop
# Fix conflicts if any
git add .
git rebase --continue
git push --force-with-lease
```

### 3. Cherry-Pick (Copy Specific Commit)
```bash
# Copy commit abc123 to current branch
git cherry-pick abc123
```

### 4. Conflict Resolution
```bash
# When conflict occurs
git status  # See conflicted files
# Edit files, remove <<<<<<< ======= >>>>>>>
git add .
git merge --continue  # or git rebase --continue
```

### 5. Stash (Save Work Temporarily)
```bash
git stash  # Save changes
git stash pop  # Restore changes
```

## When to Use What

- **Merge**: Integrating feature → develop (preserves history)
- **Rebase**: Cleaning up commits before PR (linear history)
- **Cherry-pick**: Backporting bug fix to release branch
- **Stash**: Switching branches with uncommitted work

## For This Project

- develop → Uses merge (allows merge commits)
- main/staging → Uses squash merge (clean history)
- release branches → May use cherry-pick for hotfixes
