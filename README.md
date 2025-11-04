# Kubernetes Cluster Setup - Bash Scripts & Ansible

Complete automation for setting up production-ready Kubernetes clusters on Debian 12.

## 📦 What's Included

### Bash Scripts (Manual Approach)
- `setup-k8s-master.sh` - Control plane/master node setup
- `setup-k8s-worker.sh` - Worker node preparation and joining

### Ansible Playbooks (Automated Approach)
- `site.yml` - Main playbook (orchestrates complete setup)
- `playbook-common.yml` - Common preparation for all nodes
- `playbook-master.yml` - Master node initialization
- `playbook-workers.yml` - Worker nodes join cluster
- `playbook-reset.yml` - Clean up and reset cluster
- `inventory.ini` - Cluster nodes inventory
- `group_vars/all.yml` - Configuration variables
- `ansible.cfg` - Ansible configuration

## 🎯 Which Method Should You Use?

| Criteria | Bash Scripts | Ansible Playbooks |
|----------|--------------|-------------------|
| **Best For** | 1-3 nodes, learning, testing | 4+ nodes, production, automation |
| **Setup Time** | 5-10 min per node | 10-15 min for entire cluster |
| **Complexity** | Simple, easy to understand | Requires Ansible knowledge |
| **Scalability** | Manual execution per node | Automated across all nodes |
| **Repeatability** | Moderate | Excellent (idempotent) |
| **Prerequisites** | Just SSH access | Ansible + SSH keys |
| **Maintenance** | Manual updates | Automated updates |

**Recommendation:**
- **Learning/Testing**: Use bash scripts
- **Production/Scale**: Use Ansible playbooks

---

# 📘 Method 1: Bash Scripts (Manual)

## Prerequisites

- Debian 12 (Bookworm) on all nodes
- Minimum 2GB RAM, 2 CPUs per node
- Root or sudo access
- Network connectivity between nodes

## Quick Start

### Step 1: Setup Master Node

```bash
# Download and make executable
chmod +x setup-k8s-master.sh

# Run the script
sudo ./setup-k8s-master.sh
```

**What it does:**
- Updates system packages
- Sets hostname to "control-plane"
- Disables swap (required by Kubernetes)
- Loads kernel modules (overlay, br_netfilter)
- Configures sysctl parameters
- Installs containerd container runtime
- Installs Kubernetes components (kubeadm, kubelet, kubectl)
- Initializes the cluster
- Configures kubectl
- Installs Flannel CNI
- Generates join command

**Output:** At the end, you'll get a join command. **Save this!**

```bash
kubeadm join 192.168.1.10:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234...
```

Also saved to: `/root/k8s-join-command.txt`

### Step 2: Setup Worker Nodes

On each worker node:

```bash
# Download and make executable
chmod +x setup-k8s-worker.sh

# Run the script
sudo ./setup-k8s-worker.sh
```

**During execution:**
- You'll be prompted to enter a hostname (e.g., worker1, worker2)
- You can optionally join immediately by pasting the join command

**Manual join (if skipped during script):**

```bash
sudo kubeadm join <master-ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

### Step 3: Verify Cluster

On master node:

```bash
# Check all nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# View detailed info
kubectl get nodes -o wide
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   10m   v1.28.15
worker1         Ready    <none>          5m    v1.28.15
worker2         Ready    <none>          5m    v1.28.15
```

## Bash Script Features

✅ **Detailed comments** explaining each step  
✅ **Color-coded output** (green=info, red=error, yellow=warning)  
✅ **Error checking** at each step  
✅ **Validation** after critical operations  
✅ **Helpful instructions** and next steps  
✅ **Progress indicators**

## Timeline

- Master setup: ~5-10 minutes
- Worker setup: ~3-5 minutes per node
- Total for 1 master + 2 workers: ~15-20 minutes

---

# 🤖 Method 2: Ansible Playbooks (Automated)

## Prerequisites

### On Control Machine (Your Laptop/Workstation)

```bash
# Install Ansible (Ubuntu/Debian)
sudo apt update
sudo apt install ansible

# Or using pip
pip3 install ansible

# Verify installation
ansible --version
```

### On All Kubernetes Nodes

- Debian 12 (Bookworm)
- Python 3 installed
- SSH access configured
- SSH keys set up (recommended) or password access

## Setup SSH Keys (Recommended)

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096

# Copy to all nodes
ssh-copy-id root@192.168.1.10  # master
ssh-copy-id root@192.168.1.21  # worker1
ssh-copy-id root@192.168.1.22  # worker2

# Test connection
ssh root@192.168.1.10
```

## Configuration

### Step 1: Configure Inventory

Edit `ansible/inventory.ini`:

```ini
[master]
control-plane ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
worker3 ansible_host=192.168.1.23 ansible_user=root

[k8s_cluster:children]
master
workers
```

**Update:**
- Replace IP addresses with your actual node IPs
- Change `ansible_user` if not using root
- Add or remove workers as needed

### Step 2: Configure Variables (Optional)

Edit `ansible/group_vars/all.yml` to customize:

```yaml
# Kubernetes version
kubernetes_version: "1.28"

# Network configuration
pod_network_cidr: "10.244.0.0/16"
control_plane_endpoint: "192.168.1.10:6443"

# CNI plugin
cni_plugin: "flannel"  # Options: flannel, calico

# Token expiry
token_ttl: "24h"
```

## Running Ansible Playbooks

### Method A: Complete Setup (Recommended)

Run everything in one command:

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml
```

This will:
1. Prepare all nodes (common setup)
2. Initialize master node
3. Join worker nodes
4. Verify cluster

**Estimated time:** 10-15 minutes

### Method B: Step-by-Step Setup

Run playbooks individually:

```bash
# Step 1: Prepare all nodes
ansible-playbook -i inventory.ini playbook-common.yml

# Step 2: Initialize master
ansible-playbook -i inventory.ini playbook-master.yml

# Step 3: Join workers
ansible-playbook -i inventory.ini playbook-workers.yml
```

### Method C: Targeted Execution

Run specific tasks using tags:

```bash
# Only system preparation
ansible-playbook -i inventory.ini site.yml --tags system

# Only install containerd
ansible-playbook -i inventory.ini site.yml --tags containerd

# Only Kubernetes installation
ansible-playbook -i inventory.ini site.yml --tags kubernetes

# Only master initialization
ansible-playbook -i inventory.ini site.yml --tags init

# Only worker join
ansible-playbook -i inventory.ini site.yml --tags join
```

## Ansible Playbook Details

### playbook-common.yml
Prepares all nodes with:
- System updates
- Hostname configuration
- Swap disable
- Kernel modules
- Sysctl parameters
- containerd installation
- Kubernetes components

### playbook-master.yml
Master node tasks:
- Check if already initialized
- Initialize cluster
- Configure kubectl
- Install CNI plugin
- Generate join command
- Display cluster info

### playbook-workers.yml
Worker node tasks:
- Check if already joined
- Retrieve join command
- Join cluster
- Verify kubelet
- Label worker nodes

### playbook-reset.yml
Cleanup tasks:
- Drain nodes
- Reset kubeadm
- Remove packages (optional)
- Clean configuration
- Reset network
- Re-enable swap (optional)

## Advanced Ansible Usage

### Dry Run (Check Mode)

Test without making changes:

```bash
ansible-playbook -i inventory.ini site.yml --check
```

### Limit to Specific Hosts

```bash
# Run only on master
ansible-playbook -i inventory.ini site.yml --limit master

# Run only on specific worker
ansible-playbook -i inventory.ini site.yml --limit worker1

# Run on multiple specific hosts
ansible-playbook -i inventory.ini site.yml --limit "master,worker1"
```

### Verbose Output

```bash
# Basic verbose
ansible-playbook -i inventory.ini site.yml -v

# More verbose
ansible-playbook -i inventory.ini site.yml -vv

# Maximum verbosity
ansible-playbook -i inventory.ini site.yml -vvv
```

### Add More Workers

1. Add new workers to `inventory.ini`
2. Run only worker playbook:

```bash
ansible-playbook -i inventory.ini playbook-common.yml --limit worker4
ansible-playbook -i inventory.ini playbook-workers.yml --limit worker4
```

### Reset Cluster

**WARNING:** This removes everything!

```bash
ansible-playbook -i inventory.ini playbook-reset.yml
```

To also reboot nodes:

```bash
ansible-playbook -i inventory.ini playbook-reset.yml --tags reboot
```

## Ansible Advantages

✅ **Idempotent** - Safe to run multiple times  
✅ **Parallel execution** - Multiple nodes simultaneously  
✅ **Centralized control** - Manage from one machine  
✅ **Error handling** - Automatic retries and validation  
✅ **Rollback capability** - Easy to reset and retry  
✅ **Scalable** - Add 10 nodes as easily as 1  
✅ **Repeatable** - Consistent results every time  
✅ **Version controlled** - Track changes in git

---

# 🔧 Common Tasks

## Regenerate Join Token

On master node (bash):

```bash
kubeadm token create --print-join-command
```

With Ansible:

```bash
ansible master -i inventory.ini -m shell -a "kubeadm token create --print-join-command"
```

## Check Cluster Status

```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

## Remove a Worker Node

### Using Bash

On master:
```bash
kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data
kubectl delete node worker1
```

On worker:
```bash
sudo kubeadm reset
```

### Using Ansible

```bash
ansible-playbook -i inventory.ini playbook-reset.yml --limit worker1
```

## Upgrade Kubernetes

### Bash Method
Follow official Kubernetes upgrade documentation

### Ansible Method
1. Update `kubernetes_version` in `group_vars/all.yml`
2. Create upgrade playbook (see Kubernetes docs)

---

# 🐛 Troubleshooting

## Common Issues

### Issue: Token Expired

**Solution:**

```bash
# Generate new token (bash)
kubeadm token create --print-join-command

# Generate new token (Ansible)
ansible master -i inventory.ini -m shell -a "kubeadm token create --print-join-command"
```

### Issue: Worker Won't Join

**Check connectivity:**

```bash
ping <master-ip>
telnet <master-ip> 6443
```

**Check logs:**

```bash
sudo journalctl -u kubelet -f
sudo systemctl status containerd
```

### Issue: Node Shows NotReady

**Check CNI pods:**

```bash
kubectl get pods -n kube-system | grep -E 'flannel|calico'
```

**Restart kubelet:**

```bash
sudo systemctl restart kubelet
```

### Issue: Ansible Connection Failed

**Check SSH:**

```bash
ansible all -i inventory.ini -m ping
```

**Check inventory:**

```bash
ansible-inventory -i inventory.ini --list
```

### Issue: API Server Connection Refused

**Check API server:**

```bash
sudo crictl ps | grep kube-apiserver
sudo journalctl -u kubelet -f
```

**Restart kubelet:**

```bash
sudo systemctl restart kubelet
```

## Reset and Start Over

### Bash Method

On each node:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/kubelet
sudo rm -rf /etc/kubernetes
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

### Ansible Method

```bash
ansible-playbook -i inventory.ini playbook-reset.yml
```

---

# 📊 Comparison Matrix

| Feature | Bash Scripts | Ansible Playbooks |
|---------|-------------|-------------------|
| Initial Setup Time | 20 min (3 nodes) | 15 min (any nodes) |
| Adding 5 Nodes | +25 min | +5 min |
| Error Recovery | Manual | Automatic |
| Documentation | Inline comments | YAML + comments |
| Learning Curve | Easy | Moderate |
| Production Ready | Yes | Yes |
| CI/CD Integration | Possible | Excellent |
| Config Management | Manual | Centralized |
| Audit Trail | Manual logs | Ansible logs |
| Team Collaboration | Good | Excellent |

---

# 🚀 Next Steps After Setup

## 1. Deploy a Test Application

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
```

## 2. Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 3. Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
```

## 4. Set Up Persistent Storage

Install a CSI driver based on your infrastructure.

## 5. Configure Monitoring

Install Prometheus and Grafana for cluster monitoring.

## 6. Set Up Backups

Configure etcd backups:

```bash
ETCDCTL_API=3 etcdctl snapshot save backup.db
```

---

# 📚 Resources

## Official Documentation
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [Ansible Docs](https://docs.ansible.com/)

## Networking
- [Flannel](https://github.com/flannel-io/flannel)
- [Calico](https://www.tigera.io/project-calico/)

## Container Runtime
- [containerd](https://containerd.io/docs/)

---

# 🤝 Contributing

Improvements welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Share your setup stories

---

# 📝 License

These scripts and playbooks are provided as-is for educational and production use.

---

# ⚡ Quick Reference

## Bash Scripts

```bash
# Master
sudo ./setup-k8s-master.sh

# Worker
sudo ./setup-k8s-worker.sh
# Then paste join command

# Get join command again
kubeadm token create --print-join-command
```

## Ansible

```bash
# Complete setup
ansible-playbook -i inventory.ini site.yml

# Reset cluster
ansible-playbook -i inventory.ini playbook-reset.yml

# Check connectivity
ansible all -i inventory.ini -m ping

# Add worker
ansible-playbook -i inventory.ini playbook-workers.yml --limit worker4
```

## kubectl

```bash
# Nodes
kubectl get nodes -o wide

# Pods
kubectl get pods -A

# Cluster info
kubectl cluster-info

# Join command
kubeadm token create --print-join-command

# Drain node
kubectl drain worker1 --ignore-daemonsets

# Delete node
kubectl delete node worker1
```

---

**Cluster Setup Time Estimates:**

| Cluster Size | Bash Method | Ansible Method |
|--------------|-------------|----------------|
| 1 master + 2 workers | ~20 min | ~12 min |
| 1 master + 5 workers | ~35 min | ~15 min |
| 1 master + 10 workers | ~60 min | ~18 min |

**Choose wisely and happy clustering!** 🎉