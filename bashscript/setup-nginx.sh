#!/bin/bash

################################################################################
# Nginx Setup Script for Kubernetes API Server Load Balancing
# 
# This script sets up Nginx as a load balancer for Kubernetes API servers
# Run this on a dedicated node (separate from master nodes)
#
# Usage: sudo ./setup-nginx.sh
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root or with sudo"
    exit 1
fi

print_status "Starting Nginx Setup for Kubernetes API Server..."
echo ""

################################################################################
# STEP 1: Update System
################################################################################
print_status "Step 1: Updating system packages..."

apt update
apt upgrade -y

print_status "System updated successfully"
echo ""

################################################################################
# STEP 2: Set Hostname
################################################################################
print_status "Step 2: Setting hostname..."

print_input "Enter hostname for this Nginx node (e.g., nginx-lb, loadbalancer):"
read -p "Hostname: " NGINX_HOSTNAME

if [ -n "$NGINX_HOSTNAME" ]; then
    hostnamectl set-hostname $NGINX_HOSTNAME
    print_status "Hostname set to: $(hostname)"
else
    print_warning "No hostname provided, keeping current: $(hostname)"
fi
echo ""

################################################################################
# STEP 3: Install Nginx
################################################################################
print_status "Step 3: Installing Nginx..."

# Install Nginx
apt install -y nginx

# Verify installation
NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
print_status "Installed: nginx/$NGINX_VERSION"
echo ""

################################################################################
# STEP 4: Collect Master Node Information
################################################################################
print_status "Step 4: Collecting master node information..."
echo ""

print_warning "You need to provide information about your master nodes"
print_warning "Each master node should have a unique name and IP address"
echo ""

# Initialize arrays
MASTER_NAMES=()
MASTER_IPS=()

# Collect master node information
print_input "How many master/control-plane nodes do you have? (minimum 1)"
read -p "Number of masters: " NUM_MASTERS

if [ -z "$NUM_MASTERS" ] || [ "$NUM_MASTERS" -lt 1 ]; then
    print_error "Invalid number of masters"
    exit 1
fi

for i in $(seq 1 $NUM_MASTERS); do
    echo ""
    print_input "Master Node $i:"
    read -p "  Name (e.g., master1): " master_name
    read -p "  IP Address: " master_ip
    
    if [ -z "$master_name" ] || [ -z "$master_ip" ]; then
        print_error "Name and IP are required"
        exit 1
    fi
    
    MASTER_NAMES+=("$master_name")
    MASTER_IPS+=("$master_ip")
    print_status "Added: $master_name ($master_ip)"
done

echo ""
print_status "Master nodes configured:"
for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}"
done
echo ""

################################################################################
# STEP 5: Get Nginx Configuration
################################################################################
print_status "Step 5: Getting Nginx configuration..."
echo ""

# Get this Nginx node's IP
NGINX_IP=$(ip route get 1 | awk '{print $7;exit}')
print_status "This Nginx node IP: $NGINX_IP"
echo ""

print_input "What port should Nginx listen on for API server?"
print_warning "Default is 6443 (same as Kubernetes API server)"
read -p "Port [6443]: " NGINX_PORT
NGINX_PORT=${NGINX_PORT:-6443}

print_status "Nginx will listen on: $NGINX_IP:$NGINX_PORT"
echo ""

################################################################################
# STEP 6: Backup Existing Nginx Configuration
################################################################################
print_status "Step 6: Backing up existing Nginx configuration..."

# Backup default config if it exists
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup created: /etc/nginx/nginx.conf.backup.*"
fi
echo ""

################################################################################
# STEP 7: Configure Nginx Stream Module
################################################################################
print_status "Step 7: Configuring Nginx for TCP load balancing..."

# Create stream configuration directory
mkdir -p /etc/nginx/stream-enabled

# Create Kubernetes API server stream configuration
cat > /etc/nginx/stream-enabled/kubernetes.conf <<EOF
################################################################################
# Nginx Stream Configuration for Kubernetes API Server Load Balancing
# Generated on: $(date)
################################################################################

# Upstream backend servers (Kubernetes master nodes)
upstream kubernetes-apiserver {
    # Load balancing method: least_conn
    # Distributes new connections to the server with the fewest connections
    # Alternative: hash \$remote_addr consistent; (for sticky sessions)
    least_conn;
    
    # Master node servers
    # Format: server IP:PORT max_fails=N fail_timeout=Ns;
    # max_fails: Number of failed attempts before marking server as down
    # fail_timeout: Time after which to retry a failed server
EOF

# Add master nodes to upstream configuration
for i in "${!MASTER_NAMES[@]}"; do
    cat >> /etc/nginx/stream-enabled/kubernetes.conf <<EOF
    server ${MASTER_IPS[$i]}:6443 max_fails=3 fail_timeout=10s;
EOF
done

cat >> /etc/nginx/stream-enabled/kubernetes.conf <<EOF
}

# TCP proxy for Kubernetes API Server
server {
    listen $NGINX_PORT;
    proxy_pass kubernetes-apiserver;
    
    # Proxy timeout settings
    proxy_timeout 10s;
    proxy_connect_timeout 5s;
    
    # Enable TCP health checks
    # Nginx will automatically mark backends as down if they fail
    health_check interval=10s fails=3 passes=2;
}
EOF

print_status "Kubernetes API server configuration created"
echo ""

################################################################################
# STEP 8: Create Nginx Main Configuration
################################################################################
print_status "Step 8: Creating Nginx main configuration..."

cat > /etc/nginx/nginx.conf <<'EOF'
################################################################################
# Nginx Main Configuration
# Optimized for Kubernetes API Server Load Balancing
################################################################################

user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

# HTTP section for status page
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Status page server
    server {
        listen 8080;
        server_name _;
        
        location /nginx-status {
            stub_status on;
            access_log off;
            allow all;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}

# Stream section for TCP/UDP load balancing
stream {
    # Logging
    log_format basic '$remote_addr [$time_local] '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$session_time "$upstream_addr" '
                     '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    
    access_log /var/log/nginx/stream-access.log basic;
    error_log /var/log/nginx/stream-error.log;
    
    # Include stream configurations
    include /etc/nginx/stream-enabled/*.conf;
}
EOF

print_status "Nginx main configuration created"
echo ""

################################################################################
# STEP 9: Validate Nginx Configuration
################################################################################
print_status "Step 9: Validating Nginx configuration..."

# Check configuration syntax
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi
echo ""

################################################################################
# STEP 10: Enable and Start Nginx
################################################################################
print_status "Step 10: Starting Nginx service..."

# Enable Nginx to start on boot
systemctl enable nginx

# Restart Nginx to apply configuration
systemctl restart nginx

# Wait a moment for service to start
sleep 3

# Verify Nginx is running
if systemctl is-active --quiet nginx; then
    print_status "Nginx is running successfully"
else
    print_error "Nginx failed to start"
    systemctl status nginx
    exit 1
fi
echo ""

################################################################################
# STEP 11: Configure Firewall (Optional)
################################################################################
print_status "Step 11: Firewall configuration..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    print_input "Do you want to configure UFW firewall rules? (y/n)"
    read -p "Configure firewall? " CONFIGURE_FW
    
    if [[ $CONFIGURE_FW =~ ^[Yy]$ ]]; then
        ufw allow $NGINX_PORT/tcp comment "Kubernetes API Server"
        ufw allow 8080/tcp comment "Nginx Status Page"
        print_status "Firewall rules configured"
    else
        print_warning "Skipping firewall configuration"
    fi
else
    print_warning "UFW not installed, skipping firewall configuration"
fi
echo ""

################################################################################
# STEP 12: Display Nginx Status
################################################################################
print_status "Step 12: Checking Nginx status..."

# Get Nginx status
systemctl status nginx --no-pager | head -n 15
echo ""

################################################################################
# STEP 13: Test Nginx
################################################################################
print_status "Step 13: Testing Nginx connectivity..."

# Test connection to Nginx port
if nc -zv localhost $NGINX_PORT 2>&1 | grep -q succeeded; then
    print_status "Nginx is accepting connections on port $NGINX_PORT"
else
    print_warning "Could not verify Nginx connectivity (this is normal before masters are initialized)"
fi

# Test status page
if curl -s http://localhost:8080/nginx-status > /dev/null; then
    print_status "Nginx status page is accessible"
else
    print_warning "Could not access Nginx status page"
fi
echo ""

################################################################################
# STEP 14: Display Configuration Summary
################################################################################
print_status "=== NGINX SETUP COMPLETE ==="
echo ""

print_status "Configuration Summary:"
echo "  Hostname: $(hostname)"
echo "  Nginx IP: $NGINX_IP"
echo "  API Server Port: $NGINX_PORT"
echo "  Number of Masters: $NUM_MASTERS"
echo ""

print_status "Master Nodes:"
for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443"
done
echo ""

print_status "Status and Health Pages:"
echo "  Status URL: http://$NGINX_IP:8080/nginx-status"
echo "  Health URL: http://$NGINX_IP:8080/health"
echo ""

################################################################################
# STEP 15: Display Next Steps
################################################################################
print_status "=== NEXT STEPS ==="
echo ""

print_warning "To use this Nginx load balancer with your Kubernetes cluster:"
echo ""
echo "1. When initializing master nodes, use this endpoint:"
echo "   ${GREEN}--control-plane-endpoint=$NGINX_IP:$NGINX_PORT${NC}"
echo ""
echo "2. Example kubeadm init command:"
echo "   ${GREEN}kubeadm init --control-plane-endpoint=$NGINX_IP:$NGINX_PORT --upload-certs${NC}"
echo ""
echo "3. For Ansible, update group_vars/all.yml:"
echo "   ${GREEN}control_plane_endpoint: \"$NGINX_IP:$NGINX_PORT\"${NC}"
echo ""
echo "4. Test Nginx is working:"
echo "   ${GREEN}curl -k https://$NGINX_IP:$NGINX_PORT/healthz${NC}"
echo "   (This will work only after masters are initialized)"
echo ""
echo "5. Monitor Nginx:"
echo "   ${GREEN}systemctl status nginx${NC}"
echo "   ${GREEN}journalctl -u nginx -f${NC}"
echo "   ${GREEN}curl http://$NGINX_IP:8080/nginx-status${NC}"
echo ""
echo "6. View stream logs:"
echo "   ${GREEN}tail -f /var/log/nginx/stream-access.log${NC}"
echo "   ${GREEN}tail -f /var/log/nginx/stream-error.log${NC}"
echo ""

################################################################################
# STEP 16: Save Configuration Info
################################################################################
print_status "Saving configuration information..."

# Save configuration details to file
cat > /root/nginx-config.txt <<EOF
================================================================================
Nginx Configuration for Kubernetes API Server
Generated on: $(date)
================================================================================

Nginx Node:
  Hostname: $(hostname)
  IP Address: $NGINX_IP
  API Server Port: $NGINX_PORT

Master Nodes:
EOF

for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443" >> /root/nginx-config.txt
done

cat >> /root/nginx-config.txt <<EOF

Status Pages:
  Status: http://$NGINX_IP:8080/nginx-status
  Health: http://$NGINX_IP:8080/health

Control Plane Endpoint:
  Use this in kubeadm init: --control-plane-endpoint=$NGINX_IP:$NGINX_PORT

Configuration Files:
  Main config: /etc/nginx/nginx.conf
  Stream config: /etc/nginx/stream-enabled/kubernetes.conf
  Backup: /etc/nginx/nginx.conf.backup.*

Useful Commands:
  Status: systemctl status nginx
  Restart: systemctl restart nginx
  Reload: systemctl reload nginx
  Logs: journalctl -u nginx -f
  Stream logs: tail -f /var/log/nginx/stream-access.log
  Status page: curl http://$NGINX_IP:8080/nginx-status
  Test: curl -k https://$NGINX_IP:$NGINX_PORT/healthz

Load Balancing:
  Algorithm: least_conn (fewest connections)
  Health check: Every 10s, 3 fails → down, 2 passes → up
  
Nginx Features:
  ✓ TCP load balancing (stream module)
  ✓ Automatic health checks
  ✓ Connection-based load distribution
  ✓ Status monitoring page
  ✓ Low resource usage

================================================================================
EOF

print_status "Configuration saved to: /root/nginx-config.txt"
echo ""

print_status "Nginx setup completed successfully!"
print_status "You can now proceed with setting up your Kubernetes master nodes"
echo ""
