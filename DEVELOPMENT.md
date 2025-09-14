# Development Workflow

## Overview

This project uses a **feature branch workflow** with automatic testing and deployment to ensure production stability.

## Branch Strategy

- **`main`** - Production-ready code, automatically deployed to production
  - 🔒 **Protected branch** - No direct pushes allowed
  - ✅ Only accepts merges from `dev` after successful testing
- **`dev`** - Development branch for new features and testing
  - 🧪 Automatically tested on every push
  - 🔄 Auto-merges to `main` if tests pass

## Setup Branch Protection

Before using this workflow, you need to protect the `main` branch:

```bash
# Run the setup script for instructions
./scripts/setup-branch-protection.sh
```

Or manually:
1. Go to GitHub → Settings → Branches
2. Add protection rule for `main` branch
3. Enable "Require pull request reviews"
4. Enable "Require status checks to pass"
5. Add status check: "Test and Deploy to Dev Environment"
6. Enable "Include administrators"

## Development Process

### 1. Feature Development

```bash
# Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name

# Make your changes
# ... code changes ...

# Commit and push
git add .
git commit -m "Add your feature"
git push origin feature/your-feature-name
```

### 2. Testing in Dev Environment

```bash
# Switch to dev branch
git checkout dev
git pull origin dev

# Merge your feature
git merge feature/your-feature-name

# Push to dev (triggers automatic testing)
git push origin dev
```

### 3. Automatic Testing & Deployment

When you push to `dev` branch:

1. **GitHub Actions** automatically:
   - Builds Docker images
   - Starts dev environment
   - Runs health checks
   - Tests basic functionality
   - If tests pass: Auto-merges to `main`
   - If tests fail: Stops and reports error

2. **Production Deployment**:
   - When `main` is updated, production is automatically deployed
   - Only tested and verified code reaches production

## Local Development

### Start Dev Environment

```bash
# Make script executable
chmod +x scripts/start-dev.sh

# Start dev environment
./scripts/start-dev.sh
```

### Test Your Changes

```bash
# Test API endpoint
curl "http://localhost:15433/?text=Hello"

# Check logs
docker compose -f docker-compose.dev.yml logs -f
```

### Stop Dev Environment

```bash
# Stop dev environment
./scripts/stop-dev.sh

# Stop and clean up volumes
./scripts/stop-dev.sh --clean
```

## Environment Differences

| Feature | Development | Production |
|---------|-------------|------------|
| Port | 15433 | 15432 |
| Logging | DEBUG | INFO |
| Replicas | 1 | 2+ |
| Data Dir | `data-dev/` | `data/` |
| Logs Dir | `logs-dev/` | `logs/` |
| Request Logging | Enabled | Disabled |

## Workflow Benefits

✅ **Production Stability** - Only tested code reaches production  
✅ **Automatic Testing** - Every change is tested before deployment  
✅ **Fast Feedback** - Immediate feedback on code changes  
✅ **Easy Rollback** - Can easily revert problematic changes  
✅ **Isolated Testing** - Dev environment doesn't affect production  

## Troubleshooting

### Dev Environment Issues

```bash
# Check container status
docker compose -f docker-compose.dev.yml ps

# View logs
docker compose -f docker-compose.dev.yml logs

# Restart dev environment
./scripts/stop-dev.sh
./scripts/start-dev.sh
```

### Production Issues

```bash
# Check production status
docker compose ps

# View production logs
docker compose logs -f

# Restart production
./scripts/start-cluster.sh
```

## Best Practices

1. **Always test in dev first** - Never push directly to main
2. **Keep features small** - Easier to test and debug
3. **Write descriptive commits** - Helps with debugging
4. **Monitor logs** - Check both dev and production logs
5. **Use meaningful branch names** - `feature/user-auth`, `bugfix/api-error`

## Emergency Procedures

### Rollback Production

```bash
# Revert to previous commit
git checkout main
git reset --hard HEAD~1
git push origin main --force

# Or revert specific commit
git revert <commit-hash>
git push origin main
```

### Stop All Environments

```bash
# Stop dev
./scripts/stop-dev.sh --clean

# Stop production
docker compose down
```

## Version Management

### Automatic Versioning

The project uses **automatic semantic versioning**:

- **Patch versions** (v1.0.1, v1.0.2) - Auto-created on successful dev merges
- **Minor versions** (v1.1.0) - Manual creation for new features
- **Major versions** (v2.0.0) - Manual creation for breaking changes

### Version Workflow

1. **Dev tests pass** → Auto-merge to main
2. **Auto-create patch tag** → v1.0.1, v1.0.2, etc.
3. **Production deployment** → Triggered by new tag

### Manual Version Management

```bash
# Check current version
./scripts/version-manager.sh current

# See what next version would be
./scripts/version-manager.sh next-patch
./scripts/version-manager.sh next-minor
./scripts/version-manager.sh next-major

# Create manual versions
./scripts/version-manager.sh create-patch   # v1.0.1
./scripts/version-manager.sh create-minor   # v1.1.0
./scripts/version-manager.sh create-major   # v2.0.0

# List recent tags
./scripts/version-manager.sh list
```

### Version Examples

- **v1.0.0** - Initial release
- **v1.0.1** - Bug fix (auto-created)
- **v1.0.2** - Another bug fix (auto-created)
- **v1.1.0** - New feature (manual)
- **v2.0.0** - Breaking change (manual)
