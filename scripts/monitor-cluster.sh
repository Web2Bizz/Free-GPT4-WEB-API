#!/bin/bash

# FreeGPT4 API Cluster Monitoring Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}FreeGPT4 API Cluster Monitoring${NC}"
echo "================================"

# Function to check service health
check_service() {
    local service=$1
    local port=$2
    local path=${3:-/}
    
    if curl -s -f "http://localhost:$port$path" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service is healthy"
        return 0
    else
        echo -e "${RED}✗${NC} $service is unhealthy"
        return 1
    fi
}

# Function to check Docker container status
check_container() {
    local container=$1
    local status=$(docker-compose ps -q $container 2>/dev/null)
    
    if [[ -n "$status" ]]; then
        local container_status=$(docker inspect --format='{{.State.Status}}' $status 2>/dev/null)
        if [[ "$container_status" == "running" ]]; then
            echo -e "${GREEN}✓${NC} $container container is running"
            return 0
        else
            echo -e "${RED}✗${NC} $container container is $container_status"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} $container container not found"
        return 1
    fi
}

# Function to show load balancing stats
show_load_balancing() {
    echo -e "${BLUE}Load Balancing Statistics:${NC}"
    
    # Get nginx access logs and count requests per upstream
    if [[ -f "logs/nginx/freegpt4_access.log" ]]; then
        echo "Recent requests distribution:"
        tail -n 100 logs/nginx/freegpt4_access.log | grep -o 'upstream: [^,]*' | sort | uniq -c | sort -nr
    else
        echo "No access logs found"
    fi
}

# Function to show resource usage
show_resources() {
    echo -e "${BLUE}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Function to show network information
show_networks() {
    echo -e "${BLUE}Network Information:${NC}"
    echo "External network:"
    docker network inspect external --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "External network not found"
    
    echo "Internal network:"
    docker network inspect internal --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "Internal network not found"
}

# Main monitoring
echo -e "${BLUE}Checking service health...${NC}"

# Check containers
check_container "nginx"
check_container "api"

echo ""

# Check HTTP endpoints
echo -e "${BLUE}Checking HTTP endpoints...${NC}"
check_service "nginx" "15432" "/health"

echo ""

# Show load balancing stats
show_load_balancing

echo ""

# Show resource usage
show_resources

echo ""

# Show network information
show_networks

echo ""

# Show recent logs
echo -e "${BLUE}Recent logs (last 10 lines):${NC}"
docker-compose logs --tail=10

echo ""

# Show service status
echo -e "${BLUE}Service status:${NC}"
docker-compose ps

echo ""

# Show disk usage
echo -e "${BLUE}Disk usage:${NC}"
du -sh logs/ 2>/dev/null || echo "No logs directory found"

echo ""

# Show uptime
echo -e "${BLUE}Uptime:${NC}"
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
