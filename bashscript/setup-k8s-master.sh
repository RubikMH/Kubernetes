#!/bin/bash

################################################################################
# Kubernetes Master/Control-Plane Setup Script for Debian 12
# 
# This script sets up a Kubernetes control plane node with etcd
# Run this script on the node that will be your master/control-plane
#
# Usage: sudo ./setup-k8s-master.sh
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root or with sudo"
    exit 1
fi

print_status "Starting Kubernetes Master Node Setup..."
echo ""

################################################################################
# STEP 1: Update System Packages
################################################################################
print_status "Step 1: Updating system packages..."

# Update the package index to get latest versions
apt update

# Upgrade all installed packages to their latest versions
apt upgrade -y

print_status "System packages updated successfully"
echo ""

################################################################################
# STEP 2: Set Hostname (Optional)
################################################################################
print_status "Step 2: Setting hostname..."

# Set a descriptive hostname for the master node
# This makes it easier to identify in kubectl get nodes
hostnamectl set-hostname control-plane

# Verify the hostname change
print_status "Hostname set to: $(hostname)"
echo ""

################################################################################
# STEP 3: Disable Swap
################################################################################
print_status "Step 3: Disabling swap..."

# Kubernetes requires swap to be disabled for proper operation
# This turns off swap immediately
swapoff -a

# This comments out swap entries in fstab to persist after reboot
# The sed command finds lines with ' swap ' and comments them out
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Verify swap is disabled (should show 0B)
print_status "Swap status:"
free -h | grep Swap
echo ""

################################################################################
# STEP 4: Load Required Kernel Modules
################################################################################
print_status "Step 4: Loading required kernel modules..."

# Create a configuration file to load necessary kernel modules at boot
# overlay: Required for OverlayFS storage driver
# br_netfilter: Required for iptables to see bridged traffic
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load the modules immediately (without waiting for reboot)
modprobe overlay
modprobe br_netfilter

# Verify modules are loaded
print_status "Verifying kernel modules..."
lsmod | grep overlay
lsmod | grep br_netfilter
echo ""

################################################################################
# STEP 5: Configure Sysctl Parameters
################################################################################
print_status "Step 5: Configuring sysctl parameters..."

# Create sysctl configuration for Kubernetes networking
# These settings enable IP forwarding and allow iptables to see bridged traffic
cat <<EOF | tee /etc/sysctl.d/k8s.conf
# Enable IP forwarding (required for pod-to-pod communication)
net.ipv4.ip_forward = 1

# Allow iptables to see bridged IPv4 traffic
net.bridge.bridge-nf-call-iptables = 1

# Allow iptables to see bridged IPv6 traffic
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply the sysctl settings immediately
sysctl --system

print_status "Sysctl parameters configured successfully"
echo ""

################################################################################
# STEP 6: Install Container Runtime (containerd)
################################################################################
print_status "Step 6: Installing containerd..."

# Install required dependencies for adding Docker repository
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Create directory for apt keyrings if it doesn't exist
mkdir -p /etc/apt/keyrings

# Download and add Docker's official GPG key
# This is used to verify package signatures
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository to apt sources
# This allows us to install containerd from Docker's repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new repository
apt update

# Install containerd (the container runtime)
apt install -y containerd.io

print_status "containerd installed successfully"
echo ""

################################################################################
# STEP 7: Configure containerd
################################################################################
print_status "Step 7: Configuring containerd..."

# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default containerd configuration
containerd config default | tee /etc/containerd/config.toml > /dev/null

# CRITICAL: Enable SystemdCgroup
# Kubernetes requires systemd cgroup driver for stability
# This sed command changes SystemdCgroup from false to true
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd to apply configuration
systemctl restart containerd

# Enable containerd to start on boot
systemctl enable containerd

# Verify containerd is running
if systemctl is-active --quiet containerd; then
    print_status "containerd is running and configured"
else
    print_error "containerd failed to start"
    exit 1
fi
echo ""

################################################################################
# STEP 8: Install Kubernetes Components
################################################################################
print_status "Step 8: Installing Kubernetes components (kubeadm, kubelet, kubectl)..."

# Add Kubernetes repository GPG key
# This is used to verify Kubernetes package signatures
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository to apt sources
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Update package index with Kubernetes repository
apt update

# Install Kubernetes components:
# - kubelet: The agent that runs on each node
# - kubeadm: Tool to bootstrap the cluster
# - kubectl: Command-line tool to interact with cluster
apt install -y kubelet kubeadm kubectl

# Hold these packages at current version (prevent accidental upgrades)
# Kubernetes version upgrades should be done carefully
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet to start on boot
systemctl enable kubelet

# Verify installation
print_status "Installed versions:"
kubeadm version
kubelet --version
kubectl version --client
echo ""

################################################################################
# STEP 9: Initialize Kubernetes Cluster
################################################################################
print_status "Step 9: Initializing Kubernetes cluster..."

# Initialize the Kubernetes control plane
# --pod-network-cidr: Specifies the IP range for pod network (required for Flannel)
# The API server will be accessible on all network interfaces
kubeadm init --pod-network-cidr=10.244.0.0/16

print_status "Kubernetes cluster initialized successfully"
echo ""

################################################################################
# STEP 10: Configure kubectl for Current User
################################################################################
print_status "Step 10: Configuring kubectl..."

# Get the actual user who ran sudo (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

# Create .kube directory for the actual user
mkdir -p $ACTUAL_HOME/.kube

# Copy admin kubeconfig to user's .kube directory
# This file contains credentials to access the cluster
cp -i /etc/kubernetes/admin.conf $ACTUAL_HOME/.kube/config

# Set proper ownership (important if run with sudo)
chown $(id -u $ACTUAL_USER):$(id -g $ACTUAL_USER) $ACTUAL_HOME/.kube/config

# Also configure for root user
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

print_status "kubectl configured for user: $ACTUAL_USER"
echo ""

################################################################################
# STEP 11: Install Pod Network Add-on (Flannel)
################################################################################
print_status "Step 11: Installing Flannel CNI (Container Network Interface)..."

# Wait a moment for API server to be fully ready
sleep 10

# Install Flannel network plugin
# This enables pod-to-pod communication across the cluster
# Must be run as the actual user, not root
su - $ACTUAL_USER -c "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

print_status "Flannel CNI installed successfully"
echo ""

################################################################################
# STEP 12: Wait for Node to be Ready
################################################################################
print_status "Step 12: Waiting for node to be ready..."

# Wait up to 3 minutes for the node to become ready
for i in {1..36}; do
    if su - $ACTUAL_USER -c "kubectl get nodes | grep -q 'Ready'"; then
        print_status "Node is ready!"
        break
    fi
    echo "Waiting for node to be ready... ($i/36)"
    sleep 5
done
echo ""

################################################################################
# STEP 13: Display Cluster Information
################################################################################
print_status "Step 13: Cluster setup complete!"
echo ""

print_status "=== CLUSTER INFORMATION ==="
echo ""

# Show node status
print_status "Node Status:"
su - $ACTUAL_USER -c "kubectl get nodes -o wide"
echo ""

# Show system pods status
print_status "System Pods Status:"
su - $ACTUAL_USER -c "kubectl get pods -n kube-system"
echo ""

# Show cluster info
print_status "Cluster Info:"
su - $ACTUAL_USER -c "kubectl cluster-info"
echo ""

################################################################################
# STEP 14: Generate Worker Join Command
################################################################################
print_status "=== WORKER NODE JOIN COMMAND ==="
echo ""
print_warning "Save this command to join worker nodes to the cluster:"
echo ""

# Generate a join token and print the complete join command
# This command should be run on worker nodes
kubeadm token create --print-join-command

echo ""
print_warning "Note: This token expires in 24 hours. To generate a new token, run:"
echo "  kubeadm token create --print-join-command"
echo ""

################################################################################
# STEP 15: Final Instructions
################################################################################
print_status "=== SETUP COMPLETE ==="
echo ""
print_status "Your Kubernetes master node is ready!"
echo ""
print_status "Next steps:"
echo "  1. Save the join command above"
echo "  2. Run the worker setup script on your worker nodes"
echo "  3. Use the join command on worker nodes to add them to the cluster"
echo ""
print_status "Useful commands:"
echo "  kubectl get nodes              # View all nodes"
echo "  kubectl get pods -A            # View all pods in all namespaces"
echo "  kubectl cluster-info           # View cluster information"
echo "  kubeadm token list             # List all tokens"
echo "  kubeadm token create --print-join-command  # Generate new join token"
echo ""

# Save join command to a file for easy reference
print_status "Join command has been saved to: /root/k8s-join-command.txt"
kubeadm token create --print-join-command > /root/k8s-join-command.txt
chmod 600 /root/k8s-join-command.txt

print_status "Master node setup completed successfully!"
