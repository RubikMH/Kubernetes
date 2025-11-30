#!/bin/bash

# Test script to verify the load balancer prompt logic

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

echo "=========================================="
echo "Testing Load Balancer Prompt Logic"
echo "=========================================="
echo ""

print_status "Step 9: Configuring control plane endpoint..."
echo ""

print_warning "Are you using a load balancer (HAProxy/NGINX/Traefik) for HA setup?"
read -p "Use load balancer? (y/n): " USE_LB

CONTROL_PLANE_ENDPOINT=""

if [[ $USE_LB =~ ^[Yy]$ ]]; then
    print_status "Load balancer configuration required"
    echo ""

    print_input "Enter the load balancer IP address:"
    read -p "Load Balancer IP: " LB_IP

    print_input "Enter the load balancer port (default: 6443):"
    read -p "Port [6443]: " LB_PORT
    LB_PORT=${LB_PORT:-6443}

    CONTROL_PLANE_ENDPOINT="${LB_IP}:${LB_PORT}"

    print_status "Control plane endpoint set to: $CONTROL_PLANE_ENDPOINT"
    echo ""
else
    print_warning "No load balancer - using single master setup"
    echo ""
fi

echo "=========================================="
print_status "Step 10: Building kubeadm init command..."
echo ""

# Build kubeadm init command
KUBEADM_INIT_CMD="kubeadm init --pod-network-cidr=10.244.0.0/16"

# Add control plane endpoint if using load balancer
if [ -n "$CONTROL_PLANE_ENDPOINT" ]; then
    KUBEADM_INIT_CMD="$KUBEADM_INIT_CMD --control-plane-endpoint=$CONTROL_PLANE_ENDPOINT --upload-certs"
    print_status "Using HA setup with control plane endpoint: $CONTROL_PLANE_ENDPOINT"
fi

echo ""
print_status "Command that would be executed:"
echo ""
echo "  $KUBEADM_INIT_CMD"
echo ""
print_status "Test completed!"
