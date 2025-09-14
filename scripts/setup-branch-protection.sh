#!/bin/bash

# Setup Branch Protection for main branch
# This script helps configure branch protection rules

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Branch Protection Setup${NC}"
echo "================================"

echo -e "${YELLOW}To protect the main branch, follow these steps:${NC}"
echo ""
echo "1. Go to your GitHub repository"
echo "2. Click Settings → Branches"
echo "3. Click 'Add rule' or 'Add branch protection rule'"
echo "4. In 'Branch name pattern' enter: main"
echo ""
echo -e "${BLUE}Required settings:${NC}"
echo "✅ Require a pull request before merging"
echo "   - Require approvals: 0 (since we have auto-merge)"
echo "   - Dismiss stale PR approvals when new commits are pushed"
echo ""
echo "✅ Require status checks to pass before merging"
echo "   - Require branches to be up to date before merging"
echo "   - Status checks: 'Test and Deploy to Dev Environment'"
echo ""
echo "✅ Require linear history (recommended)"
echo "✅ Restrict pushes that create files"
echo "✅ Include administrators (IMPORTANT!)"
echo ""
echo -e "${BLUE}Optional additional settings:${NC}"
echo "✅ Require conversation resolution before merging"
echo "✅ Require signed commits"
echo "✅ Require deployments to succeed before merging"
echo ""
echo -e "${GREEN}After setup, the workflow will be:${NC}"
echo "1. All changes must go through dev branch"
echo "2. Dev branch is automatically tested"
echo "3. Only successful tests can merge to main"
echo "4. Direct pushes to main will be blocked"
echo ""
echo -e "${YELLOW}Note: You can still force push to main if needed for emergencies${NC}"
echo "   (but this should be avoided in normal workflow)"
