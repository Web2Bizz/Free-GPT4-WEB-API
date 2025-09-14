#!/bin/bash

# FreeGPT4 API Scaling Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_REPLICAS=2
DEFAULT_MEMORY_LIMIT=512M
DEFAULT_MEMORY_RESERVATION=256M

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  scale <replicas>     Scale API to specified number of replicas"
    echo "  up                   Start all services with default replicas"
    echo "  down                 Stop all services"
    echo "  restart              Restart all services"
    echo "  status               Show status of all services"
    echo "  logs [service]       Show logs (optionally for specific service)"
    echo "  health               Check health of all services"
    echo ""
    echo "Options:"
    echo "  --memory-limit <size>     Set memory limit (e.g., 512M, 1G)"
    echo "  --memory-reservation <size> Set memory reservation (e.g., 256M, 512M)"
    echo ""
    echo "Examples:"
    echo "  $0 scale 4                    # Scale to 4 replicas"
    echo "  $0 scale 2 --memory-limit 1G  # Scale to 2 replicas with 1GB limit"
    echo "  $0 up                         # Start with default settings"
    echo "  $0 status                     # Show current status"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed or not in PATH"
        exit 1
    fi
}

# Function to scale API
scale_api() {
    local replicas=$1
    local memory_limit=${2:-$DEFAULT_MEMORY_LIMIT}
    local memory_reservation=${3:-$DEFAULT_MEMORY_RESERVATION}
    
    print_status "Scaling API to $replicas replicas..."
    print_status "Memory limit: $memory_limit"
    print_status "Memory reservation: $memory_reservation"
    
    # Export environment variables
    export API_REPLICAS=$replicas
    export API_MEMORY_LIMIT=$memory_limit
    export API_MEMORY_RESERVATION=$memory_reservation
    
    # Scale the service
    docker-compose up -d --scale api=$replicas
    
    print_success "API scaled to $replicas replicas"
    
    # Show status
    print_status "Current status:"
    docker-compose ps
}

# Function to start services
start_services() {
    local memory_limit=${1:-$DEFAULT_MEMORY_LIMIT}
    local memory_reservation=${2:-$DEFAULT_MEMORY_RESERVATION}
    
    print_status "Starting FreeGPT4 API cluster..."
    
    # Export environment variables
    export API_REPLICAS=${API_REPLICAS:-$DEFAULT_REPLICAS}
    export API_MEMORY_LIMIT=$memory_limit
    export API_MEMORY_RESERVATION=$memory_reservation
    
    # Start services
    docker-compose up -d
    
    print_success "Services started"
    
    # Show status
    print_status "Current status:"
    docker-compose ps
}

# Function to stop services
stop_services() {
    print_status "Stopping FreeGPT4 API cluster..."
    docker-compose down
    print_success "Services stopped"
}

# Function to restart services
restart_services() {
    print_status "Restarting FreeGPT4 API cluster..."
    docker-compose restart
    print_success "Services restarted"
}

# Function to show status
show_status() {
    print_status "FreeGPT4 API Cluster Status:"
    docker-compose ps
    echo ""
    print_status "Service details:"
    docker-compose config --services | while read service; do
        echo "  - $service"
    done
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -n "$service" ]; then
        print_status "Showing logs for $service:"
        docker-compose logs -f "$service"
    else
        print_status "Showing logs for all services:"
        docker-compose logs -f
    fi
}

# Function to check health
check_health() {
    print_status "Checking health of all services..."
    
    # Check nginx
    if curl -f http://localhost:15432/health > /dev/null 2>&1; then
        print_success "Nginx: Healthy"
    else
        print_error "Nginx: Unhealthy"
    fi
    
    # Check API models endpoint
    if curl -f http://localhost:15432/models > /dev/null 2>&1; then
        print_success "API: Healthy"
    else
        print_error "API: Unhealthy"
    fi
    
    # Show container health
    print_status "Container health status:"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}"
}

# Main script logic
main() {
    check_docker_compose
    
    case "${1:-}" in
        "scale")
            if [ -z "${2:-}" ]; then
                print_error "Please specify number of replicas"
                show_usage
                exit 1
            fi
            scale_api "$2" "$3" "$4"
            ;;
        "up")
            start_services "$2" "$3"
            ;;
        "down")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "health")
            check_health
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: ${1:-}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
