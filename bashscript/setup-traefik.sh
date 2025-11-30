#!/bin/bash

################################################################################
# Traefik Setup Script for Kubernetes API Server Load Balancing
# 
# This script sets up Traefik as a load balancer for Kubernetes API servers
# Run this on a dedicated node (separate from master nodes)
#
# Usage: sudo ./setup-traefik.sh
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

print_status "Starting Traefik Setup for Kubernetes API Server..."
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

print_input "Enter hostname for this Traefik node (e.g., traefik-lb, loadbalancer):"
read -p "Hostname: " TRAEFIK_HOSTNAME

if [ -n "$TRAEFIK_HOSTNAME" ]; then
    hostnamectl set-hostname $TRAEFIK_HOSTNAME
    print_status "Hostname set to: $(hostname)"
else
    print_warning "No hostname provided, keeping current: $(hostname)"
fi
echo ""

################################################################################
# STEP 3: Install Traefik
################################################################################
print_status "Step 3: Installing Traefik..."

# Get latest Traefik version
TRAEFIK_VERSION=$(curl -s https://api.github.com/repos/traefik/traefik/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
print_status "Latest Traefik version: $TRAEFIK_VERSION"

# Download Traefik binary
cd /tmp
wget "https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz"
tar -xzf "traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz"

# Install Traefik
mv traefik /usr/local/bin/
chmod +x /usr/local/bin/traefik

# Verify installation
INSTALLED_VERSION=$(traefik version | head -1)
print_status "Installed: $INSTALLED_VERSION"
echo ""

################################################################################
# STEP 4: Create Traefik User
################################################################################
print_status "Step 4: Creating Traefik user..."

# Create traefik user
if ! id -u traefik &>/dev/null; then
    useradd -r -M -s /bin/false traefik
    print_status "Created traefik user"
else
    print_status "Traefik user already exists"
fi
echo ""

################################################################################
# STEP 5: Collect Master Node Information
################################################################################
print_status "Step 5: Collecting master node information..."
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
# STEP 6: Get Traefik Configuration
################################################################################
print_status "Step 6: Getting Traefik configuration..."
echo ""

# Get this Traefik node's IP
TRAEFIK_IP=$(ip route get 1 | awk '{print $7;exit}')
print_status "This Traefik node IP: $TRAEFIK_IP"
echo ""

print_input "What port should Traefik listen on for API server?"
print_warning "Default is 6443 (same as Kubernetes API server)"
read -p "Port [6443]: " TRAEFIK_PORT
TRAEFIK_PORT=${TRAEFIK_PORT:-6443}

print_status "Traefik will listen on: $TRAEFIK_IP:$TRAEFIK_PORT"
echo ""

################################################################################
# STEP 7: Create Traefik Directories
################################################################################
print_status "Step 7: Creating Traefik directories..."

# Create configuration directory
mkdir -p /etc/traefik/dynamic
mkdir -p /var/log/traefik

# Set permissions
chown -R traefik:traefik /etc/traefik
chown -R traefik:traefik /var/log/traefik

print_status "Directories created"
echo ""

################################################################################
# STEP 8: Create Traefik Static Configuration
################################################################################
print_status "Step 8: Creating Traefik static configuration..."

cat > /etc/traefik/traefik.yml <<EOF
################################################################################
# Traefik Static Configuration for Kubernetes API Server Load Balancing
# Generated on: $(date)
################################################################################

# Global configuration
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# Entry points (ports Traefik listens on)
entryPoints:
  kubernetes-api:
    address: ":$TRAEFIK_PORT"
    # TCP mode for Kubernetes API server
    transport:
      respondingTimeouts:
        readTimeout: 60s
        writeTimeout: 60s
        idleTimeout: 180s
  
  # Dashboard and API
  dashboard:
    address: ":8080"

# API and Dashboard
api:
  dashboard: true
  insecure: true  # Allow HTTP access (change for production)

# Logging
log:
  level: INFO
  filePath: /var/log/traefik/traefik.log
  format: common

# Access logs
accessLog:
  filePath: /var/log/traefik/access.log
  format: common
  bufferingSize: 100

# Metrics (Prometheus format)
metrics:
  prometheus:
    entryPoint: dashboard
    addEntryPointsLabels: true
    addServicesLabels: true

# Health check
ping:
  entryPoint: dashboard

# Dynamic configuration provider
providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true
EOF

print_status "Static configuration created: /etc/traefik/traefik.yml"
echo ""

################################################################################
# STEP 9: Create Traefik Dynamic Configuration
################################################################################
print_status "Step 9: Creating Traefik dynamic configuration..."

cat > /etc/traefik/dynamic/kubernetes.yml <<EOF
################################################################################
# Traefik Dynamic Configuration - Kubernetes API Server Backends
# Generated on: $(date)
################################################################################

tcp:
  routers:
    kubernetes-api:
      entryPoints:
        - kubernetes-api
      rule: "HostSNI(\`*\`)"
      service: kubernetes-masters
      tls:
        passthrough: true

  services:
    kubernetes-masters:
      loadBalancer:
        # Load balancing strategy
        # Options: wrr (weighted round robin) - default
        strategy: wrr
        
        # Backend servers (Kubernetes master nodes)
        servers:
EOF

# Add master nodes to dynamic configuration
for i in "${!MASTER_NAMES[@]}"; do
    cat >> /etc/traefik/dynamic/kubernetes.yml <<EOF
          - address: "${MASTER_IPS[$i]}:6443"
EOF
done

cat >> /etc/traefik/dynamic/kubernetes.yml <<EOF

        # Health check configuration
        healthCheck:
          interval: "10s"
          timeout: "5s"
EOF

print_status "Dynamic configuration created: /etc/traefik/dynamic/kubernetes.yml"
echo ""

################################################################################
# STEP 10: Create Traefik Systemd Service
################################################################################
print_status "Step 10: Creating Traefik systemd service..."

cat > /etc/systemd/system/traefik.service <<EOF
[Unit]
Description=Traefik Load Balancer
Documentation=https://doc.traefik.io/traefik/
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=traefik
Group=traefik
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml
Restart=on-failure
RestartSec=5s

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/traefik

# Allow binding to privileged ports
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd service created"
echo ""

################################################################################
# STEP 11: Enable and Start Traefik
################################################################################
print_status "Step 11: Starting Traefik service..."

# Reload systemd
systemctl daemon-reload

# Enable Traefik to start on boot
systemctl enable traefik

# Start Traefik
systemctl start traefik

# Wait a moment for service to start
sleep 5

# Verify Traefik is running
if systemctl is-active --quiet traefik; then
    print_status "Traefik is running successfully"
else
    print_error "Traefik failed to start"
    systemctl status traefik
    exit 1
fi
echo ""

################################################################################
# STEP 12: Configure Firewall (Optional)
################################################################################
print_status "Step 12: Firewall configuration..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    print_input "Do you want to configure UFW firewall rules? (y/n)"
    read -p "Configure firewall? " CONFIGURE_FW
    
    if [[ $CONFIGURE_FW =~ ^[Yy]$ ]]; then
        ufw allow $TRAEFIK_PORT/tcp comment "Kubernetes API Server"
        ufw allow 8080/tcp comment "Traefik Dashboard"
        print_status "Firewall rules configured"
    else
        print_warning "Skipping firewall configuration"
    fi
else
    print_warning "UFW not installed, skipping firewall configuration"
fi
echo ""

################################################################################
# STEP 13: Display Traefik Status
################################################################################
print_status "Step 13: Checking Traefik status..."

# Get Traefik status
systemctl status traefik --no-pager | head -n 15
echo ""

################################################################################
# STEP 14: Test Traefik
################################################################################
print_status "Step 14: Testing Traefik connectivity..."

# Test connection to Traefik port
if nc -zv localhost $TRAEFIK_PORT 2>&1 | grep -q succeeded; then
    print_status "Traefik is accepting connections on port $TRAEFIK_PORT"
else
    print_warning "Could not verify Traefik connectivity (this is normal before masters are initialized)"
fi

# Test dashboard
if curl -s http://localhost:8080/api/overview > /dev/null; then
    print_status "Traefik dashboard is accessible"
else
    print_warning "Could not access Traefik dashboard"
fi
echo ""

################################################################################
# STEP 15: Display Configuration Summary
################################################################################
print_status "=== TRAEFIK SETUP COMPLETE ==="
echo ""

print_status "Configuration Summary:"
echo "  Hostname: $(hostname)"
echo "  Traefik IP: $TRAEFIK_IP"
echo "  API Server Port: $TRAEFIK_PORT"
echo "  Number of Masters: $NUM_MASTERS"
echo ""

print_status "Master Nodes:"
for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443"
done
echo ""

print_status "Dashboard and Monitoring:"
echo "  Dashboard URL: http://$TRAEFIK_IP:8080/dashboard/"
echo "  API URL: http://$TRAEFIK_IP:8080/api/overview"
echo "  Metrics URL: http://$TRAEFIK_IP:8080/metrics"
echo "  Health URL: http://$TRAEFIK_IP:8080/ping"
echo ""

################################################################################
# STEP 16: Display Next Steps
################################################################################
print_status "=== NEXT STEPS ==="
echo ""

print_warning "To use this Traefik load balancer with your Kubernetes cluster:"
echo ""
echo "1. When initializing master nodes, use this endpoint:"
echo "   ${GREEN}--control-plane-endpoint=$TRAEFIK_IP:$TRAEFIK_PORT${NC}"
echo ""
echo "2. Example kubeadm init command:"
echo "   ${GREEN}kubeadm init --control-plane-endpoint=$TRAEFIK_IP:$TRAEFIK_PORT --upload-certs${NC}"
echo ""
echo "3. For Ansible, update group_vars/all.yml:"
echo "   ${GREEN}control_plane_endpoint: \"$TRAEFIK_IP:$TRAEFIK_PORT\"${NC}"
echo ""
echo "4. Test Traefik is working:"
echo "   ${GREEN}curl -k https://$TRAEFIK_IP:$TRAEFIK_PORT/healthz${NC}"
echo "   (This will work only after masters are initialized)"
echo ""
echo "5. Monitor Traefik:"
echo "   ${GREEN}systemctl status traefik${NC}"
echo "   ${GREEN}journalctl -u traefik -f${NC}"
echo "   ${GREEN}Open browser: http://$TRAEFIK_IP:8080/dashboard/${NC}"
echo ""
echo "6. View logs:"
echo "   ${GREEN}tail -f /var/log/traefik/traefik.log${NC}"
echo "   ${GREEN}tail -f /var/log/traefik/access.log${NC}"
echo ""

################################################################################
# STEP 17: Save Configuration Info
################################################################################
print_status "Saving configuration information..."

# Save configuration details to file
cat > /root/traefik-config.txt <<EOF
================================================================================
Traefik Configuration for Kubernetes API Server
Generated on: $(date)
================================================================================

Traefik Node:
  Hostname: $(hostname)
  IP Address: $TRAEFIK_IP
  API Server Port: $TRAEFIK_PORT
  Version: $TRAEFIK_VERSION

Master Nodes:
EOF

for i in "${!MASTER_NAMES[@]}"; do
    echo "  - ${MASTER_NAMES[$i]}: ${MASTER_IPS[$i]}:6443" >> /root/traefik-config.txt
done

cat >> /root/traefik-config.txt <<EOF

Dashboard and Monitoring:
  Dashboard: http://$TRAEFIK_IP:8080/dashboard/
  API: http://$TRAEFIK_IP:8080/api/overview
  Metrics: http://$TRAEFIK_IP:8080/metrics (Prometheus format)
  Health: http://$TRAEFIK_IP:8080/ping

Control Plane Endpoint:
  Use this in kubeadm init: --control-plane-endpoint=$TRAEFIK_IP:$TRAEFIK_PORT

Configuration Files:
  Static config: /etc/traefik/traefik.yml
  Dynamic config: /etc/traefik/dynamic/kubernetes.yml
  Systemd service: /etc/systemd/system/traefik.service

Log Files:
  Main log: /var/log/traefik/traefik.log
  Access log: /var/log/traefik/access.log

Useful Commands:
  Status: systemctl status traefik
  Restart: systemctl restart traefik
  Reload config: systemctl reload traefik
  Logs: journalctl -u traefik -f
  View logs: tail -f /var/log/traefik/traefik.log
  Test: curl -k https://$TRAEFIK_IP:$TRAEFIK_PORT/healthz

Load Balancing:
  Strategy: Weighted Round Robin (WRR)
  Health check: Every 10s, timeout 5s
  TLS: Passthrough (no termination)
  
Traefik Features:
  ✓ Modern cloud-native load balancer
  ✓ Automatic service discovery
  ✓ Real-time dashboard
  ✓ Prometheus metrics built-in
  ✓ TCP/HTTP/HTTPS support
  ✓ Dynamic configuration reload
  ✓ Health checks with automatic failover

Dashboard Access:
  Open in browser: http://$TRAEFIK_IP:8080/dashboard/
  No authentication (configure for production)

================================================================================
EOF

print_status "Configuration saved to: /root/traefik-config.txt"
echo ""

print_status "Traefik setup completed successfully!"
print_status "You can now proceed with setting up your Kubernetes master nodes"
echo ""

print_warning "Production Security Note:"
echo "The dashboard is currently accessible without authentication."
echo "For production, enable authentication in /etc/traefik/traefik.yml"
echo ""
