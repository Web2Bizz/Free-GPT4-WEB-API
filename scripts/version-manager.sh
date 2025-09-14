#!/bin/bash

# Version Management Script for FreeGPT4 API

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get current version
get_current_version() {
    git fetch --tags > /dev/null 2>&1
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo $LATEST_TAG
}

# Function to increment version
increment_version() {
    local version=$1
    local increment_type=$2
    
    # Remove 'v' prefix
    version=$(echo $version | sed 's/v//')
    
    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    MAJOR=${VERSION_PARTS[0]:-0}
    MINOR=${VERSION_PARTS[1]:-0}
    PATCH=${VERSION_PARTS[2]:-0}
    
    case $increment_type in
        "major")
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        "minor")
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        "patch")
            PATCH=$((PATCH + 1))
            ;;
        *)
            echo "Invalid increment type. Use: major, minor, or patch"
            exit 1
            ;;
    esac
    
    echo "v$MAJOR.$MINOR.$PATCH"
}

# Function to create and push tag
create_tag() {
    local version=$1
    local message=$2
    
    echo -e "${BLUE}Creating tag: $version${NC}"
    git tag -a "$version" -m "$message"
    git push origin "$version"
    echo -e "${GREEN}Successfully created and pushed tag: $version${NC}"
}

# Main script
case "$1" in
    "current")
        echo -e "${BLUE}Current version:${NC} $(get_current_version)"
        ;;
    "next-patch")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "patch")
        echo -e "${BLUE}Current version:${NC} $CURRENT"
        echo -e "${GREEN}Next patch version:${NC} $NEXT"
        ;;
    "next-minor")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "minor")
        echo -e "${BLUE}Current version:${NC} $CURRENT"
        echo -e "${GREEN}Next minor version:${NC} $NEXT"
        ;;
    "next-major")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "major")
        echo -e "${BLUE}Current version:${NC} $CURRENT"
        echo -e "${GREEN}Next major version:${NC} $NEXT"
        ;;
    "create-patch")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "patch")
        MESSAGE="Release $NEXT - Patch version"
        create_tag $NEXT "$MESSAGE"
        ;;
    "create-minor")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "minor")
        MESSAGE="Release $NEXT - Minor version"
        create_tag $NEXT "$MESSAGE"
        ;;
    "create-major")
        CURRENT=$(get_current_version)
        NEXT=$(increment_version $CURRENT "major")
        MESSAGE="Release $NEXT - Major version"
        create_tag $NEXT "$MESSAGE"
        ;;
    "list")
        echo -e "${BLUE}Recent tags:${NC}"
        git tag --sort=-version:refname | head -10
        ;;
    *)
        echo -e "${GREEN}FreeGPT4 API Version Manager${NC}"
        echo "=============================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  current        - Show current version"
        echo "  next-patch     - Show next patch version"
        echo "  next-minor     - Show next minor version"
        echo "  next-major     - Show next major version"
        echo "  create-patch   - Create and push patch version"
        echo "  create-minor   - Create and push minor version"
        echo "  create-major   - Create and push major version"
        echo "  list           - List recent tags"
        echo ""
        echo "Examples:"
        echo "  $0 current           # Show current version"
        echo "  $0 next-patch        # Show what next patch would be"
        echo "  $0 create-patch      # Create and push patch version"
        echo ""
        echo -e "${YELLOW}Note: Automatic versioning happens on successful dev merges${NC}"
        ;;
esac
