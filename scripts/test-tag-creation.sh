#!/bin/bash

# Test script to verify tag creation and workflow triggers

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Testing Tag Creation and Workflow Triggers${NC}"
echo "============================================="

# Check current branch
echo -e "${BLUE}Current branch:${NC}"
git branch --show-current

# Check current tags
echo -e "${BLUE}Current tags:${NC}"
git tag --sort=-version:refname | head -5

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Warning: Not on main branch. Current branch: $CURRENT_BRANCH${NC}"
    echo "Switching to main branch..."
    git checkout main
    git pull origin main
fi

# Get latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo -e "${BLUE}Latest tag:${NC} $LATEST_TAG"

# Calculate next version
VERSION=$(echo $LATEST_TAG | sed 's/v//')
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

NEW_PATCH=$((PATCH + 1))
NEW_VERSION="v$MAJOR.$MINOR.$NEW_PATCH"

echo -e "${BLUE}Next version would be:${NC} $NEW_VERSION"

# Ask if user wants to create test tag
echo ""
echo -e "${YELLOW}Do you want to create a test tag to trigger production workflow? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Creating test tag: $NEW_VERSION${NC}"
    
    # Create tag
    git tag -a "$NEW_VERSION" -m "Test release $NEW_VERSION - Triggering production workflow"
    
    # Push tag
    git push origin "$NEW_VERSION"
    
    echo -e "${GREEN}Tag $NEW_VERSION created and pushed!${NC}"
    echo -e "${YELLOW}This should trigger the production deployment workflow.${NC}"
    echo "Check the Actions tab in GitHub to see if the workflow starts."
else
    echo -e "${YELLOW}Test tag creation cancelled.${NC}"
fi

echo ""
echo -e "${BLUE}To check workflow status:${NC}"
echo "1. Go to GitHub Actions tab"
echo "2. Look for 'Deploy to Production' workflow"
echo "3. Check if it was triggered by the tag push"
