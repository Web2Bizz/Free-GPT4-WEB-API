#!/bin/bash

# FreeGPT4 API Log Management Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SERVICE_NAME="api"
LOG_FILE="logs/freegpt4.log"
FOLLOW=false
LEVEL=""
LINES=50

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --follow          Follow log output in real-time"
    echo "  -l, --lines N         Number of lines to show (default: 50)"
    echo "  --level LEVEL         Filter by log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)"
    echo "  --file FILE           Log file to read (default: logs/freegpt4.log)"
    echo "  --service NAME        Docker service name (default: api)"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -f                                    # Follow logs in real-time"
    echo "  $0 -l 100                               # Show last 100 lines"
    echo "  $0 --level ERROR                        # Show only ERROR logs"
    echo "  $0 --file logs/freegpt4-dev.log -f      # Follow dev logs"
    echo "  $0 --service api --level DEBUG -l 200   # Show last 200 DEBUG lines from api service"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not running or not accessible${NC}"
        exit 1
    fi
}

# Function to check if service is running
check_service() {
    if ! docker-compose ps $SERVICE_NAME | grep -q "Up"; then
        echo -e "${YELLOW}Warning: Service '$SERVICE_NAME' is not running${NC}"
        echo "Starting service..."
        docker-compose up -d $SERVICE_NAME
        sleep 5
    fi
}

# Function to show logs
show_logs() {
    local cmd="docker-compose logs"
    
    if [ "$FOLLOW" = true ]; then
        cmd="$cmd -f"
    fi
    
    if [ "$LINES" -gt 0 ]; then
        cmd="$cmd --tail=$LINES"
    fi
    
    cmd="$cmd $SERVICE_NAME"
    
    if [ -n "$LEVEL" ]; then
        echo -e "${BLUE}Filtering logs by level: $LEVEL${NC}"
        eval $cmd | grep -i "$LEVEL"
    else
        eval $cmd
    fi
}

# Function to show log file
show_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}Error: Log file '$LOG_FILE' not found${NC}"
        exit 1
    fi
    
    local cmd="tail"
    
    if [ "$FOLLOW" = true ]; then
        cmd="tail -f"
    fi
    
    if [ "$LINES" -gt 0 ]; then
        cmd="$cmd -n $LINES"
    fi
    
    if [ -n "$LEVEL" ]; then
        echo -e "${BLUE}Filtering logs by level: $LEVEL${NC}"
        $cmd "$LOG_FILE" | grep -i "$LEVEL"
    else
        $cmd "$LOG_FILE"
    fi
}

# Function to clean old logs
clean_logs() {
    echo -e "${YELLOW}Cleaning old log files...${NC}"
    
    # Remove log files older than 7 days
    find logs/ -name "*.log*" -type f -mtime +7 -delete
    
    # Compress log files older than 1 day
    find logs/ -name "*.log" -type f -mtime +1 -exec gzip {} \;
    
    echo -e "${GREEN}Log cleanup completed${NC}"
}

# Function to show log statistics
show_stats() {
    echo -e "${BLUE}Log Statistics:${NC}"
    echo "=================="
    
    if [ -f "$LOG_FILE" ]; then
        echo "File: $LOG_FILE"
        echo "Size: $(du -h "$LOG_FILE" | cut -f1)"
        echo "Lines: $(wc -l < "$LOG_FILE")"
        echo "Last modified: $(stat -c %y "$LOG_FILE" 2>/dev/null || stat -f %Sm "$LOG_FILE")"
        echo ""
        
        echo "Log level distribution:"
        echo "DEBUG:   $(grep -c "DEBUG" "$LOG_FILE" 2>/dev/null || echo 0)"
        echo "INFO:    $(grep -c "INFO" "$LOG_FILE" 2>/dev/null || echo 0)"
        echo "WARNING: $(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo 0)"
        echo "ERROR:   $(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo 0)"
        echo "CRITICAL: $(grep -c "CRITICAL" "$LOG_FILE" 2>/dev/null || echo 0)"
    else
        echo -e "${RED}Log file not found: $LOG_FILE${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -l|--lines)
            LINES="$2"
            shift 2
            ;;
        --level)
            LEVEL="$2"
            shift 2
            ;;
        --file)
            LOG_FILE="$2"
            shift 2
            ;;
        --service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        --clean)
            clean_logs
            exit 0
            ;;
        --stats)
            show_stats
            exit 0
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
check_docker

# If LOG_FILE is specified, read from file, otherwise use Docker logs
if [[ "$LOG_FILE" == "logs/"* ]]; then
    show_log_file
else
    check_service
    show_logs
fi
