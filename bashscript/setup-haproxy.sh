#!/bin/bash

################################################################################
# HAProxy Setup Script for Kubernetes API Server Load Balancing
# 
# This script sets up HAProxy as a load balancer for Kubernetes API servers
# Run this on a dedicated node (separate from master nodes)
#
# Usage: sudo ./setup-haproxy.sh
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

print_status "Starting HAProxy Setup for Kubernetes API Server..."
echo ""

################################################################################
# STEP 1: Update System
################################################################################
print_status "Step 1: Updating system packages..."

# Update package index
apt update

# Upgrade packages
apt upgrade -y

print_status "System updated successfully"
echo ""

################################################################################
# STEP 2: Set Hostname
################################################################################
print_status "Step 2: Setting hostname..."

# Prompt for hostname
print_input "Enter hostname for this HAProxy node (e.g., haproxy, lb):"
read -p "Hostname: " HAPROXY_HOSTNAME

if [ -n "$HAPROXY_HOSTNAME" ]; then
    hostnamectl set-hostname $HAPROXY_HOSTNAME
    print_status "Hostname set to: $(hostname)"
else
    print_warning "No hostname provided, keeping current: $(hostname)"
fi
echo ""

################################################################################
# STEP 3: Install HAProxy
################################################################################
print_status "Step 3: Installing HAProxy..."

# Install HAProxy package
apt install -y haproxy

# Verify installation
HAPROXY_VERSION=$(haproxy -v | head -1)
print_status "Installed: $HAPROXY_VERSION"
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
# STEP 5: Get HAProxy VIP Information
################################################################################
print_status "Step 5: Getting HAProxy virtual IP information..."
echo ""

# Get this HAProxy node's IP
HAPROXY_IP=$(ip route get 1 | awk '{print $7;exit}')
print_status "This HAProxy node IP: $HAPROXY_IP"
echo ""

print_input "What port should HAProxy listen on for API server?"
print_warning "Default is 6443 (same as Kubernetes API server)"
read -p "Port [6443]: " HAPROXY_PORT
HAPROXY_PORT=${HAPROXY_PORT:-6443}

print_status "HAProxy will listen on: $HAPROXY_IP:$HAPROXY_PORT"
echo ""

################################################################################
# STEP 6: Backup Existing HAProxy Configuration
################################################################################
print_status "Step 6: Backing up existing HAProxy configuration..."

# Backup original config if it exists
if [ -f /etc/haproxy/haproxy.cfg ]; then
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup created: /etc/haproxy/haproxy.cfg.backup.*"
fi
echo ""

################################################################################
# STEP 7: Configure HAProxy
################################################################################
print_status "Step 7: Configuring HAProxy for Kubernetes API Server..."

# Create HAProxy configuration
cat > /etc/haproxy/haproxy.cfg <<EOF
################################################################################
# HAProxy Configuration for Kubernetes API Server Load Balancing
# Generated on: $(date)
################################################################################

global
    # Global settings
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Increase default maxconn
    maxconn 4000

    # TLS configuration
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    # Default settings for all sections
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

################################################################################
# Frontend Configuration - Kubernetes API Server
################################################################################
frontend kubernetes-api
    # Description: Frontend for Kubernetes API Server
    # This accepts incoming connections on port $HAPROXY_PORT
    bind *:$HAPROXY_PORT
    mode tcp
    option tcplog
    default_backend kubernetes-master-nodes

################################################################################
# Backend Configuration - Kubernetes Master Nodes
################################################################################
backend kubernetes-master-nodes
    # Description: Backend pool of Kubernetes master nodes
    # Load balancing algorithm: roundrobin (distributes requests evenly)
    mode tcp
    option tcp-check
    balance roundrobin
    
    # Health check: Verify API server is responding
    # This sends a TCP connection check to ensure the API server is alive
    option tcp-check
    
    # Master node servers
EOF

# Add master nodes to backend configuration
for i in "${!MASTER_NAMES[@]}"; do
    cat >> /etc/haproxy/haproxy.cfg <<EOF
    server ${MASTER_NAMES[$i]} ${MASTER_IPS[$i]}:6443 check fall 3 rise 2
EOF
done

# Add statistics page configuration
cat >> /etc/haproxy/haproxy.cfg <<EOF

################################################################################
# Statistics Page
################################################################################
listen stats
    # HAProxy statistics page
    bind *:9000
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
    stats auth admin:$(openssl rand -base64 12)
EOF

print_status "HAProxy configuration created"
echo ""

################################################################################
# STEP 8: Validate HAProxy Configuration
################################################################################
print_status "Step 8: Validating HAProxy configuration..."

# Check configuration syntax
if haproxy -c -f /etc/haproxy/haproxy.cfg; then
    print_status "HAProxy configuration is valid"
else
    print_error "HAProxy configuration has errors"
    exit 1
fi
echo ""

################################################################################
# STEP 9: Enable and Start HAProxy
################################################################################
print_status "Step 9: Starting HAProxy service..."

# Enable HAProxy to start on boot
systemctl enable haproxy

# Restart HAProxy to apply configuration
systemctl restart haproxy

# Wait a moment for service to start
sleep 3

# Verify HAProxy is running
if systemctl is-active --quiet haproxy; then
    print_status "HAProxy is running successfully"
else
    print_error "HAProxy failed to start"
    systemctl status haproxy
    exit 1
fi
echo ""

################################################################################
# STEP 10: Configure Firewall (Optional)
################################################################################
print_status "Step 10: Firewall configuration..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    print_input "Do you want to configure UFW firewall rules? (y/n)"
    read -p "Configure firewall? " CONFIGURE_FW
    
    if [[ $CONFIGURE_FW =~ ^[Yy]$ ]]; then
        ufw allow $HAPROXY_PORT/tcp comment "Kubernetes API Server"
        ufw allow 9000/tcp comment "HAProxy Statistics"
        print_status "Firewall rules configured"
    else
        print_warning "Skipping firewall configuration"
    fi
else
    print_warning "UFW not installed, skipping firewall configuration"
fi
echo ""

################################################################################
# STEP 11: Display HAProxy Status
################################################################################
print_status "Step 11: Checking HAProxy status..."

# Get HAProxy status
systemctl status haproxy --no-pager | head -n 15
echo ""

################################################################################
# STEP 12: Test HAProxy
################################################################################
print_status "Step 12: Testing HAProxy connectivity..."

# Test connection to HAProxy port
if nc -zv localhost $HAPROXY_PORT 2>&1 | grep -q succeeded; then
    print_status "HAProxy is accepting connections on port $HAPROXY_PORT"
else
    print_warning "Could not verify HAProxy connectivity (this is normal before masters are initialized)"
fi
echo ""

################################################################################
# STEP 13: Display Configuration Summary
################################################################################
print_status "=== HAPROXY SETUP COMPLETE ==="
echo ""

print_status "Configuration Summary:"
echo "  Hostname: $(hostname)"
echo "  HAProxy IP: $HAPROXY_IP"
echo "  API Server Port: $HAPROXY_PORT"
echo "  Number of Masters: $NUM_MASTERS"
echo ""

print_status "Master Nodes:"
for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443"
done
echo ""

print_status "Statistics Page:"
STATS_PASSWORD=$(grep "stats auth" /etc/haproxy/haproxy.cfg | awk '{print $3}' | cut -d: -f2)
echo "  URL: http://$HAPROXY_IP:9000/stats"
echo "  Username: admin"
echo "  Password: $STATS_PASSWORD"
echo ""

print_warning "IMPORTANT: Save the statistics password above!"
echo ""

################################################################################
# STEP 14: Display Next Steps
################################################################################
print_status "=== NEXT STEPS ==="
echo ""

print_warning "To use this HAProxy with your Kubernetes cluster:"
echo ""
echo "1. When initializing master nodes, use this endpoint:"
echo "   ${GREEN}--control-plane-endpoint=$HAPROXY_IP:$HAPROXY_PORT${NC}"
echo ""
echo "2. Example kubeadm init command:"
echo "   ${GREEN}kubeadm init --control-plane-endpoint=$HAPROXY_IP:$HAPROXY_PORT --upload-certs${NC}"
echo ""
echo "3. For Ansible, update group_vars/all.yml:"
echo "   ${GREEN}control_plane_endpoint: \"$HAPROXY_IP:$HAPROXY_PORT\"${NC}"
echo ""
echo "4. Test HAProxy is working:"
echo "   ${GREEN}curl -k https://$HAPROXY_IP:$HAPROXY_PORT/healthz${NC}"
echo "   (This will work only after masters are initialized)"
echo ""
echo "5. Monitor HAProxy:"
echo "   ${GREEN}systemctl status haproxy${NC}"
echo "   ${GREEN}journalctl -u haproxy -f${NC}"
echo ""

################################################################################
# STEP 15: Save Configuration Info
################################################################################
print_status "Saving configuration information..."

# Save configuration details to file
cat > /root/haproxy-config.txt <<EOF
================================================================================
HAProxy Configuration for Kubernetes API Server
Generated on: $(date)
================================================================================

HAProxy Node:
  Hostname: $(hostname)
  IP Address: $HAPROXY_IP
  API Server Port: $HAPROXY_PORT

Master Nodes:
EOF

for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443" >> /root/haproxy-config.txt
done

cat >> /root/haproxy-config.txt <<EOF

Statistics Page:
  URL: http://$HAPROXY_IP:9000/stats
  Username: admin
  Password: $STATS_PASSWORD

Control Plane Endpoint:
  Use this in kubeadm init: --control-plane-endpoint=$HAPROXY_IP:$HAPROXY_PORT

Configuration File:
  Location: /etc/haproxy/haproxy.cfg
  Backup: /etc/haproxy/haproxy.cfg.backup.*

Useful Commands:
  Status: systemctl status haproxy
  Restart: systemctl restart haproxy
  Logs: journalctl -u haproxy -f
  Test: curl -k https://$HAPROXY_IP:$HAPROXY_PORT/healthz

================================================================================
EOF

print_status "Configuration saved to: /root/haproxy-config.txt"
echo ""

print_status "HAProxy setup completed successfully!"
print_status "You can now proceed with setting up your Kubernetes master nodes"
echo ""
