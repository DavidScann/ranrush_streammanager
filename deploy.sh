#!/bin/bash

# Tournament Dashboard Deployment Script
# This script helps deploy the tournament dashboard on a server with nginx

set -e  # Exit on any error

echo "🚀 Tournament Dashboard Deployment Script"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="tournament-dashboard"
APP_DIR="/var/www/ranrush_streammanager"
SERVICE_FILE="/etc/systemd/system/tournament-dashboard.service"
NGINX_CONF="/etc/nginx/sites-available/tournament-dashboard"
NGINX_ENABLED="/etc/nginx/sites-enabled/tournament-dashboard"

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root for security reasons."
    print_error "Please run as a regular user with sudo privileges."
    exit 1
fi

# Check if required commands exist
check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("node" "npm" "nginx" "systemctl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is not installed. Please install it first."
            exit 1
        fi
    done
    
    print_status "All dependencies found!"
}

# Install Node.js dependencies
install_deps() {
    print_status "Installing Node.js dependencies..."
    npm install --production
    print_status "Dependencies installed!"
}

# Create logs directory
create_logs_dir() {
    print_status "Creating logs directory..."
    mkdir -p logs
    chmod 755 logs
}

# Setup systemd service
setup_service() {
    print_status "Setting up systemd service..."
    
    # Update the service file with correct paths
    sudo cp tournament-dashboard.service "$SERVICE_FILE"
    sudo sed -i "s|/var/www/ranrush_streammanager|$(pwd)|g" "$SERVICE_FILE"
    sudo sed -i "s|User=www-data|User=$(whoami)|g" "$SERVICE_FILE"
    sudo sed -i "s|ReadWritePaths=/var/www/ranrush_streammanager|ReadWritePaths=$(pwd)|g" "$SERVICE_FILE"
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable "$APP_NAME"
    
    print_status "Systemd service configured!"
}

# Setup nginx configuration
setup_nginx() {
    print_status "Setting up nginx configuration..."
    
    # Copy nginx config
    sudo cp nginx.conf "$NGINX_CONF"
    
    # Update paths in nginx config
    sudo sed -i "s|/path/to/your/ranrush_streammanager|$(pwd)|g" "$NGINX_CONF"
    
    # Ask for domain name
    read -p "Enter your domain name (or IP address): " domain
    if [[ -n "$domain" ]]; then
        sudo sed -i "s|your-domain.com|$domain|g" "$NGINX_CONF"
    else
        print_warning "No domain specified, using default 'your-domain.com'"
    fi
    
    # Enable site
    sudo ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
    
    # Test nginx configuration
    if sudo nginx -t; then
        print_status "Nginx configuration is valid!"
    else
        print_error "Nginx configuration test failed!"
        exit 1
    fi
    
    print_status "Nginx configured!"
}

# Start services
start_services() {
    print_status "Starting services..."
    
    # Start the Node.js application
    sudo systemctl start "$APP_NAME"
    sleep 2
    
    # Check if service is running
    if sudo systemctl is-active --quiet "$APP_NAME"; then
        print_status "Tournament dashboard service started successfully!"
    else
        print_error "Failed to start tournament dashboard service!"
        sudo systemctl status "$APP_NAME"
        exit 1
    fi
    
    # Restart nginx
    sudo systemctl restart nginx
    
    if sudo systemctl is-active --quiet nginx; then
        print_status "Nginx restarted successfully!"
    else
        print_error "Failed to restart nginx!"
        exit 1
    fi
}

# Setup firewall (optional)
setup_firewall() {
    if command -v ufw &> /dev/null; then
        read -p "Do you want to configure UFW firewall? (y/n): " setup_fw
        if [[ "$setup_fw" =~ ^[Yy]$ ]]; then
            print_status "Configuring UFW firewall..."
            sudo ufw allow 'Nginx Full'
            sudo ufw --force enable
            print_status "Firewall configured!"
        fi
    fi
}

# Main deployment function
deploy() {
    print_status "Starting deployment process..."
    
    check_dependencies
    install_deps
    create_logs_dir
    setup_service
    setup_nginx
    start_services
    setup_firewall
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "=================================="
    echo ""
    echo "Your tournament dashboard is now running!"
    echo ""
    echo "📱 Access your dashboard at:"
    if [[ -n "$domain" ]]; then
        echo "   http://$domain"
        echo "   https://$domain (if SSL is configured)"
    else
        echo "   http://your-server-ip"
    fi
    echo ""
    echo "📁 Data file location: $(pwd)/data.json"
    echo ""
    echo "🔧 Useful commands:"
    echo "   sudo systemctl status $APP_NAME    # Check service status"
    echo "   sudo systemctl restart $APP_NAME   # Restart service"
    echo "   sudo systemctl logs $APP_NAME      # View logs"
    echo "   sudo nginx -t                      # Test nginx config"
    echo ""
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  deploy     Full deployment (default)"
    echo "  restart    Restart services"
    echo "  status     Show service status"
    echo "  logs       Show application logs"
    echo "  update     Update application (git pull + restart)"
    echo "  help       Show this help message"
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    sudo systemctl restart "$APP_NAME"
    sudo systemctl restart nginx
    print_status "Services restarted!"
}

# Show status
show_status() {
    echo "Service Status:"
    echo "==============="
    sudo systemctl status "$APP_NAME" --no-pager
    echo ""
    echo "Nginx Status:"
    echo "============="
    sudo systemctl status nginx --no-pager
}

# Show logs
show_logs() {
    print_status "Showing recent logs..."
    sudo journalctl -u "$APP_NAME" -f
}

# Update application
update_app() {
    print_status "Updating application..."
    
    if [[ -d .git ]]; then
        git pull
        npm install --production
        restart_services
        print_status "Application updated!"
    else
        print_warning "No git repository found. Please update manually."
    fi
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "restart")
        restart_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "update")
        update_app
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac