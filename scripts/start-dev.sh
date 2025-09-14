#!/bin/bash

# FreeGPT4 API Development Environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}FreeGPT4 API Development Environment${NC}"
echo "=========================================="

# Set development environment variables
export LOG_LEVEL=DEBUG
export ENABLE_REQUEST_LOGGING=true
export PRIVATE_MODE=false
export PROVIDER=You
export REMOVE_SOURCES=true
export ENV=development

# Create necessary directories for dev
echo -e "${BLUE}Creating development directories...${NC}"
mkdir -p logs/nginx-dev
mkdir -p logs-dev
mkdir -p llm-api-service/data-dev

# Set proper permissions for data directories
echo -e "${BLUE}Setting permissions for dev directories...${NC}"
chmod -R 777 llm-api-service/data-dev
chmod -R 777 logs-dev
chmod -R 777 logs/nginx-dev

# Ensure directories are owned by current user
echo -e "${BLUE}Setting ownership for dev directories...${NC}"
chown -R $(id -u):$(id -g) llm-api-service/data-dev
chown -R $(id -u):$(id -g) logs-dev
chown -R $(id -u):$(id -g) logs/nginx-dev

# Create networks if they don't exist
echo -e "${BLUE}Creating Docker networks...${NC}"
docker network create external 2>/dev/null || echo "External network already exists"
docker network create internal 2>/dev/null || echo "Internal network already exists"

# Stop any existing dev containers
echo -e "${BLUE}Stopping existing dev containers...${NC}"
docker compose -f docker-compose.dev.yml down 2>/dev/null || true

# Build and start the dev environment
echo -e "${BLUE}Building and starting dev environment...${NC}"
docker compose -f docker-compose.dev.yml up -d --build

# Wait for services to be ready
echo -e "${YELLOW}Waiting for dev services to be ready...${NC}"
sleep 20

# Check service status
echo -e "${BLUE}Checking dev service status...${NC}"
docker compose -f docker-compose.dev.yml ps

# Show logs
echo -e "${BLUE}Recent dev logs:${NC}"
docker compose -f docker-compose.dev.yml logs --tail=20

echo -e "${GREEN}Dev environment started successfully!${NC}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo "- nginx (reverse proxy): http://localhost:15433"
echo "- api (dev instance): internal network only"
echo ""
echo -e "${YELLOW}Features:${NC}"
echo "- Debug logging enabled"
echo "- Request logging enabled"
echo "- Single replica for faster testing"
echo "- Separate data directories"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "docker compose -f docker-compose.dev.yml logs -f"
echo ""
echo -e "${YELLOW}To stop:${NC}"
echo "docker compose -f docker-compose.dev.yml down"
echo ""
echo -e "${YELLOW}To test API:${NC}"
echo "curl 'http://localhost:15433/?text=Hello'"
