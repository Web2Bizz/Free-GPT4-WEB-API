#!/bin/bash

# FreeGPT4 API Cluster with Load Balancing and SSL

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if domain is provided
if [[ -z "$1" ]]; then
    echo -e "${RED}Error: Domain is required${NC}"
    echo "Usage: $0 <domain> [email]"
    echo "Example: $0 api.example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-admin@example.com}

echo -e "${GREEN}FreeGPT4 API Cluster with Load Balancing and SSL${NC}"
echo "======================================================"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Set environment variables
export LOG_LEVEL=${LOG_LEVEL:-INFO}
export LOG_FILE=${LOG_FILE:-/app/logs/freegpt4.log}
export ENABLE_REQUEST_LOGGING=${ENABLE_REQUEST_LOGGING:-false}
export PRIVATE_MODE=${PRIVATE_MODE:-false}
export COOKIE_FILE=${COOKIE_FILE:-/app/data/cookies.json}
export PROVIDER=${PROVIDER:-You}
export REMOVE_SOURCES=${REMOVE_SOURCES:-true}
export SSL_DOMAIN=$DOMAIN
export SSL_EMAIL=$EMAIL

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

# Request SSL certificate
echo -e "${YELLOW}Requesting SSL certificate...${NC}"
docker-compose run --rm certbot

# Restart nginx to load SSL certificates
echo -e "${YELLOW}Restarting nginx with SSL certificates...${NC}"
docker-compose restart nginx

# Check service status
echo -e "${BLUE}Checking service status...${NC}"
docker-compose ps

# Show logs
echo -e "${BLUE}Recent logs:${NC}"
docker-compose logs --tail=20

echo -e "${GREEN}Cluster with SSL started successfully!${NC}"
echo ""
echo -e "${YELLOW}Services:${NC}"
echo "- nginx (reverse proxy): https://$DOMAIN"
echo "- api1 (replica 1): internal network only"
echo "- api2 (replica 2): internal network only"
echo ""
echo -e "${YELLOW}Load balancing:${NC}"
echo "- Round-robin distribution between api1 and api2"
echo "- Health checks enabled"
echo "- Rate limiting configured"
echo "- SSL/TLS encryption enabled"
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
