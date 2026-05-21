## GitHub Setup & Push Instructions

Your Git repository has been initialized locally with all project files committed.

### Step 1: Create a GitHub Repository

1. Go to [github.com](https://github.com) and sign in
2. Click **+** (top-right) → **New repository**
3. Name it: `NorthStar-FMCG-DataWarehouse` (or your preferred name)
4. Description: `End-to-end Data Warehouse PoC for FMCG Supply Chain`
5. Choose **Public** or **Private** (recommended: Private for sensitive data)
6. **Do NOT** initialize with README, .gitignore, or license (we already have these)
7. Click **Create repository**

### Step 2: Add Remote & Push to GitHub

After creating the repository on GitHub, you'll see commands. Copy your repository URL (HTTPS or SSH).

Run the following commands in PowerShell:

```powershell
# Replace with your actual GitHub username and repository name
git remote add origin https://github.com/YOUR_USERNAME/NorthStar-FMCG-DataWarehouse.git

# Verify the remote was added
git remote -v

# Push to GitHub (this creates the main branch)
git branch -M main
git push -u origin main
```

### Step 3: Verify on GitHub

1. Refresh your GitHub repository page
2. You should see all files (README.md, sql/, diagrams/, etc.)
3. The commit history will show your initial commit

### Additional Commands

Update `.gitignore` to exclude CSVs (if they contain sensitive data):
```powershell
# Edit .gitignore and uncomment: # *.csv
# Then:
git add .gitignore
git commit -m "Update gitignore: exclude CSV data files"
git push
```

Add new features / updates:
```powershell
# Make your changes, then:
git add .
git commit -m "Descriptive commit message"
git push origin main
```

### Notes

- If you use SSH instead of HTTPS, generate SSH keys first:
  - On Windows: Use `ssh-keygen -t rsa -b 4096`
  - Add the public key to GitHub Settings → SSH and GPG keys
- If you get authentication errors with HTTPS, use GitHub Personal Access Token (PAT) instead of your password
- For teams: consider setting up branch protection rules and pull request workflows on GitHub

---

For more help, see: https://docs.github.com/en/repositories/creating-and-managing-repositories
