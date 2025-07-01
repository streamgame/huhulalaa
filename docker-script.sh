#!/bin/bash

# Docker Compose Management Script for win10.yaml
# Usage: ./docker-manager.sh [command]

# Function to install Docker and Docker Compose
install_docker() {
    print_header "Installing Docker and Docker Compose"
    
    print_status "Updating package lists..."
    sudo apt update
    
    print_status "Installing containerd..."
    sudo apt install -y containerd
    
    print_status "Installing docker.io and docker-compose..."
    sudo apt install -y docker.io docker-compose
    
    print_status "Installing Docker Compose standalone (latest version)..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_status "Adding current user to docker group..."
    sudo usermod -aG docker $USER
    
    print_status "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_status "Docker installation completed!"
    print_warning "Please log out and log back in for group changes to take effect."
    print_status "Or run: newgrp docker"
    
    # Check versions
    echo ""
    print_header "Installed Versions"
    docker --version
    docker-compose --version
}

COMPOSE_FILE="win10.yaml"

# Auto-detect Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="sudo docker-compose -f $COMPOSE_FILE"
    COMPOSE_VERSION="V1"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="sudo docker compose -f $COMPOSE_FILE"
    COMPOSE_VERSION="V2"
else
    print_error "Docker Compose not found! Please install Docker Compose."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if win10.yaml exists
check_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "File $COMPOSE_FILE not found!"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install       - Install Docker and Docker Compose"
    echo "  commit        - Commit Docker and Docker Compose"
    echo "  up, start     - Start containers"
    echo "  down, stop    - Stop and remove containers"
    echo "  restart       - Restart containers"
    echo "  logs          - Show logs (follow mode)"
    echo "  logs-static   - Show logs (static)"
    echo "  status, ps    - Show container status"
    echo "  pull          - Pull latest images"
    echo "  build         - Build containers"
    echo "  clean         - Stop containers and remove volumes"
    echo "  help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install   # Install Docker first"
    echo "  $0 up"
    echo "  $0 logs"
    echo "  $0 status"
}

# Main functions
docker_commit_push() {
    print_header "Commit and push"
    docker commit windows garymiltonfoster/custom-windows10:v1.0
    docker commit ngrok-rdp garymiltonfoster/custom-ngrok:v1.0
    docker commit url-display garymiltonfoster/custom-url-display:v1.0
    docker push garymiltonfoster/custom-windows10:v1.0
    docker push garymiltonfoster/custom-ngrok:v1.0
    docker push garymiltonfoster/custom-url-display:v1.0
    print_header "Done-Commit and push"
}

docker_up() {
    print_header "Starting Docker Containers"
    check_file
    $DOCKER_COMPOSE_CMD up -d
    if [ $? -eq 0 ]; then
        print_status "Containers started successfully!"
        print_status "Windows VM will be available at: http://localhost:8006"
        print_status "RDP access: localhost:3389"
    else
        print_error "Failed to start containers!"
    fi
}

docker_down() {
    print_header "Stopping Docker Containers"
    check_file
    $DOCKER_COMPOSE_CMD down
    if [ $? -eq 0 ]; then
        print_status "Containers stopped successfully!"
    else
        print_error "Failed to stop containers!"
    fi
}

docker_restart() {
    print_header "Restarting Docker Containers"
    check_file
    $DOCKER_COMPOSE_CMD down
    sleep 2
    $DOCKER_COMPOSE_CMD up -d
    if [ $? -eq 0 ]; then
        print_status "Containers restarted successfully!"
    else
        print_error "Failed to restart containers!"
    fi
}

docker_logs() {
    print_header "Showing Docker Logs (Press Ctrl+C to exit)"
    check_file
    $DOCKER_COMPOSE_CMD logs -f
}

docker_logs_static() {
    print_header "Showing Docker Logs (Static)"
    check_file
    $DOCKER_COMPOSE_CMD logs --tail=50
}

docker_status() {
    print_header "Container Status"
    check_file
    $DOCKER_COMPOSE_CMD ps
    echo ""
    print_status "All containers:"
    sudo docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

docker_pull() {
    print_header "Pulling Latest Images"
    check_file
    $DOCKER_COMPOSE_CMD pull
}

docker_build() {
    print_header "Building Containers"
    check_file
    $DOCKER_COMPOSE_CMD build
}

docker_clean() {
    print_header "Cleaning Up (Stop + Remove Volumes)"
    check_file
    print_warning "This will remove all containers and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $DOCKER_COMPOSE_CMD down -v
        print_status "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Main script logic
case "$1" in
    "commit"|"push")
        docker_commit_push
        ;;
    "install")
        install_docker
        ;;    
    "up"|"start")
        docker_up
        ;;
    "down"|"stop")
        docker_down
        ;;
    "restart")
        docker_restart
        ;;
    "logs")
        docker_logs
        ;;
    "logs-static")
        docker_logs_static
        ;;
    "status"|"ps")
        docker_status
        ;;
    "pull")
        docker_pull
        ;;
    "build")
        docker_build
        ;;
    "clean")
        docker_clean
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    "")
        print_warning "No command specified."
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
