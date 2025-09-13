#!/bin/bash

# FreeGPT4 API Cluster with Load Balancing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}FreeGPT4 API Cluster with Load Balancing${NC}"
echo "=============================================="

# Set default environment variables
export LOG_LEVEL=${LOG_LEVEL:-INFO}
export LOG_FILE=${LOG_FILE:-/app/logs/freegpt4.log}
export ENABLE_REQUEST_LOGGING=${ENABLE_REQUEST_LOGGING:-false}
export PRIVATE_MODE=${PRIVATE_MODE:-false}
export COOKIE_FILE=${COOKIE_FILE:-/app/data/cookies.json}
export PROVIDER=${PROVIDER:-You}
export REMOVE_SOURCES=${REMOVE_SOURCES:-true}

# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p logs/nginx
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p llm-api-service/data

# Create networks if they don't exist
echo -e "${BLUE}Creating Docker networks...${NC}"
docker network create external 2>/dev/null || echo "External network already exists"
docker network create internal 2>/dev/null || echo "Internal network already exists"

# Start the cluster
echo -e "${BLUE}Starting FreeGPT4 API cluster...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 15

# Check service status
echo -e "${BLUE}Checking service status...${NC}"
docker-compose ps

# Show logs
echo -e "${BLUE}Recent logs:${NC}"
docker-compose logs --tail=20

echo -e "${GREEN}Cluster started successfully!${NC}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo "- nginx (reverse proxy): http://localhost:80, https://localhost:443"
echo "- api1 (replica 1): internal network only"
echo "- api2 (replica 2): internal network only"
echo ""
echo -e "${YELLOW}Load balancing:${NC}"
echo "- Round-robin distribution between api1 and api2"
echo "- Health checks enabled"
echo "- Rate limiting configured"
echo ""
echo -e "${YELLOW}Networks:${NC}"
echo "- external: nginx, certbot"
echo "- internal: nginx, api1, api2 (isolated from external access)"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "docker-compose logs -f"
echo ""
echo -e "${YELLOW}To stop:${NC}"
echo "docker-compose down"
