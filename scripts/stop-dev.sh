#!/bin/bash

# Stop FreeGPT4 API Development Environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping FreeGPT4 API Development Environment${NC}"
echo "================================================"

# Stop dev containers
echo -e "${BLUE}Stopping dev containers...${NC}"
docker compose -f docker-compose.dev.yml down

# Clean up dev volumes (optional)
if [[ "$1" == "--clean" ]]; then
    echo -e "${BLUE}Cleaning up dev volumes...${NC}"
    docker compose -f docker-compose.dev.yml down -v
    docker system prune -f
fi

echo -e "${GREEN}Dev environment stopped successfully!${NC}"
