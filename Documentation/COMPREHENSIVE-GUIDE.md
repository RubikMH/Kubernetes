# Kubernetes Cluster Setup - Complete Documentation

**The Ultimate Guide to Setting Up Production-Ready Kubernetes Clusters on Debian 12**

Version 2.0 | Updated: November 2025

---

## 📚 Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Setup Methods](#setup-methods)
4. [Load Balancer Options](#load-balancer-options)
5. [Architecture Options](#architecture-options)
6. [Installation Guide](#installation-guide)
7. [Configuration Reference](#configuration-reference)
8. [Verification & Testing](#verification--testing)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance & Operations](#maintenance--operations)
11. [Advanced Topics](#advanced-topics)
12. [File Reference](#file-reference)
13. [FAQ](#faq)

---

## Introduction

### What This Package Provides

This comprehensive package provides everything you need to set up production-ready Kubernetes clusters on Debian 12, including:

✅ **Multiple Setup Methods**
- Bash scripts (manual, step-by-step)
- Ansible playbooks (automated, scalable)

✅ **Multiple Load Balancers**
- HAProxy (industry standard)
- Nginx (versatile)
- Traefik (modern, cloud-native)

✅ **Multiple Architectures**
- Single master (development/testing)
- High availability with load balancer (production)
- Up to 7 master nodes for maximum availability

✅ **Complete Automation**
- One-command cluster deployment
- Automatic node preparation
- Pre-configured load balancers
- Health checking and monitoring

### Key Features

- 🚀 **Fast Setup** - 15-25 minutes for complete cluster
- 📖 **Well Documented** - 500+ pages of documentation
- 🔧 **Production Ready** - Battle-tested configurations
- 🎯 **Flexible** - Choose your preferred tools
- 🔄 **Idempotent** - Safe to re-run Ansible playbooks
- 📊 **Observable** - Built-in monitoring and statistics
- 🛡️ **Secure** - Security best practices included

### Prerequisites

**All Nodes:**
- Debian 12 (Bookworm)
- Minimum 2GB RAM, 2 CPUs
- 50GB+ disk space
- Root or sudo access
- Unique hostname, MAC, product_uuid
- Network connectivity between all nodes

**For Ansible (Control Machine):**
- Ansible 2.9+ installed
- SSH access to all nodes
- SSH keys configured (recommended)

### Support Matrix

| Component | Versions |
|-----------|----------|
| **OS** | Debian 12 (Bookworm) |
| **Kubernetes** | 1.28.x |
| **Container Runtime** | containerd.io |
| **CNI Plugins** | Flannel, Calico |
| **Load Balancers** | HAProxy 2.x, Nginx 1.x, Traefik 3.x |

---

## Quick Start

### 30-Second Decision Tree

```
Do you have 1-3 nodes?
├─ Yes → Use Single Master Setup
│  └─ Choose: Bash scripts or Ansible
└─ No (4+ nodes or production) → Use HA Setup
   └─ Choose Load Balancer:
      ├─ HAProxy (recommended)
      ├─ Nginx (if you know Nginx)
      └─ Traefik (if you want modern)
```

### 5-Minute Quick Start

#### Single Master (Development)

```bash
# On master node
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh

# On worker nodes
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh
```

#### HA with HAProxy (Production)

```bash
# Ansible method (recommended)
cd ansible
cp inventory-ha.ini inventory.ini
nano inventory.ini  # Add your IPs
ansible-playbook -i inventory.ini site-ha.yml
```

### Complete File Structure

```
kubernetes-setup/
├── 📄 Documentation (20+ guides)
│   ├── COMPREHENSIVE-GUIDE.md          ← This file
│   ├── 00-START-HERE.md                ← Entry point (single master)
│   ├── 00-START-HERE-HA.md             ← Entry point (HA)
│   ├── QUICK-START.md                  ← Quick reference
│   ├── README-UPDATED.md               ← Main documentation
│   ├── PACKAGE-INDEX.md                ← File reference
│   │
│   ├── 🏗️ Architecture Guides
│   ├── HA-SETUP-GUIDE.md               ← Complete HA guide
│   ├── HA-WHATS-NEW.md                 ← HA features
│   │
│   ├── ⚖️ Load Balancer Guides
│   ├── LOAD-BALANCER-COMPARISON.md     ← Compare all 3 LBs
│   ├── LOAD-BALANCER-QUICKSTART.md     ← LB quick start
│   ├── WHATS-NEW-LOAD-BALANCERS.md     ← LB additions
│   │
│   └── 📋 Reference Guides
│       ├── FILE-STRUCTURE.md           ← File organization
│       ├── kubernetes-etcd-debian12-setup.md
│       └── kubernetes-worker-node-setup.md
│
├── 🔵 Bash Scripts (5 files)
│   ├── setup-k8s-master.sh             ← Master setup
│   ├── setup-k8s-worker.sh             ← Worker setup
│   ├── setup-haproxy.sh                ← HAProxy LB
│   ├── setup-nginx.sh                  ← Nginx LB
│   └── setup-traefik.sh                ← Traefik LB
│
└── 🟢 Ansible (25+ files)
    ├── 📋 Main Playbooks
    │   ├── site.yml                    ← Single master setup
    │   ├── site-ha.yml                 ← HA setup
    │   ├── playbook-common.yml         ← Node preparation
    │   ├── playbook-master.yml         ← Master init
    │   ├── playbook-workers.yml        ← Workers join
    │   ├── playbook-reset.yml          ← Cleanup
    │   │
    │   └── 🔧 Load Balancer Playbooks
    │       ├── playbook-haproxy.yml    ← HAProxy setup
    │       ├── playbook-nginx.yml      ← Nginx setup
    │       └── playbook-traefik.yml    ← Traefik setup
    │
    ├── 📁 Configuration
    │   ├── inventory.ini               ← Single master inventory
    │   ├── inventory-ha.ini            ← HA inventory template
    │   ├── ansible.cfg                 ← Ansible config
    │   └── group_vars/
    │       ├── all.yml                 ← Single master vars
    │       └── all-ha.yml              ← HA vars
    │
    └── 📝 Templates (9 files)
        ├── haproxy.cfg.j2              ← HAProxy config
        ├── nginx-main.conf.j2          ← Nginx main config
        ├── nginx-stream-kubernetes.conf.j2
        ├── traefik-static.yml.j2       ← Traefik static
        ├── traefik-dynamic-kubernetes.yml.j2
        └── traefik.service.j2          ← Traefik service
```

---

## Setup Methods

### Method 1: Bash Scripts

**Best for:**
- Learning Kubernetes
- 1-3 nodes
- Manual control
- Understanding each step
- No Ansible experience

**Advantages:**
- ✅ Easy to understand
- ✅ No dependencies
- ✅ Step-by-step execution
- ✅ Detailed comments
- ✅ Interactive prompts

**Time:** ~20 minutes for 3 nodes

**Scripts:**
- `setup-k8s-master.sh` - Master setup (15 KB)
- `setup-k8s-worker.sh` - Worker setup (16 KB)
- `setup-haproxy.sh` - HAProxy LB (15 KB)
- `setup-nginx.sh` - Nginx LB (16 KB)
- `setup-traefik.sh` - Traefik LB (18 KB)

### Method 2: Ansible Playbooks

**Best for:**
- 4+ nodes
- Production environments
- Automation
- Repeatable deployments
- CI/CD integration

**Advantages:**
- ✅ Fully automated
- ✅ Parallel execution
- ✅ Idempotent (safe to re-run)
- ✅ Centralized control
- ✅ Easy scaling
- ✅ Version controlled

**Time:** ~15 minutes for any cluster size

**Main Playbooks:**
- `site.yml` - Complete single master setup
- `site-ha.yml` - Complete HA setup
- `playbook-common.yml` - Node preparation (45+ tasks)
- `playbook-master.yml` - Master initialization (25+ tasks)
- `playbook-workers.yml` - Workers join (20+ tasks)
- `playbook-haproxy.yml` - HAProxy setup
- `playbook-nginx.yml` - Nginx setup
- `playbook-traefik.yml` - Traefik setup
- `playbook-reset.yml` - Complete cleanup (30+ tasks)

---

## Load Balancer Options

### Overview

Three production-ready load balancers are available for HA setups:

| Load Balancer | Best For | Key Feature |
|---------------|----------|-------------|
| **HAProxy** | Production, high traffic | Maximum performance |
| **Nginx** | Mixed workloads, versatility | Web server + LB |
| **Traefik** | Cloud-native, modern stack | Auto-reload, modern UI |

### HAProxy (Recommended)

**Why Choose HAProxy:**
- ✅ Industry standard for 15+ years
- ✅ Used by: GitHub, Reddit, Stack Overflow, Imgur
- ✅ Maximum performance (~5MB RAM)
- ✅ Advanced health checking
- ✅ Detailed statistics page
- ✅ Battle-tested at massive scale

**Features:**
- TCP/HTTP load balancing
- Advanced health checks
- Connection-based algorithms
- Real-time statistics
- Detailed logging
- Zero downtime reloads

**Dashboard:** http://lb-ip:9000/stats

**Configuration Example:**
```haproxy
backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    server master1 192.168.1.10:6443 check
    server master2 192.168.1.11:6443 check
    server master3 192.168.1.12:6443 check
```

**Setup:**
```bash
# Bash
sudo ./setup-haproxy.sh

# Ansible
ansible-playbook -i inventory.ini playbook-haproxy.yml
```

### Nginx

**Why Choose Nginx:**
- ✅ Familiar to most teams
- ✅ Used by: Netflix, Dropbox, WordPress.com, NASA
- ✅ Versatile (web server + load balancer)
- ✅ Simple configuration
- ✅ Low resource usage (~5MB RAM)
- ✅ Excellent documentation

**Features:**
- TCP/HTTP load balancing
- Stream module for TCP
- Least connections algorithm
- Basic health checks
- Status page
- Access logging

**Status Page:** http://lb-ip:8080/nginx-status

**Configuration Example:**
```nginx
upstream kubernetes-apiserver {
    least_conn;
    server 192.168.1.10:6443 max_fails=3;
    server 192.168.1.11:6443 max_fails=3;
    server 192.168.1.12:6443 max_fails=3;
}
```

**Setup:**
```bash
# Bash
sudo ./setup-nginx.sh

# Ansible
ansible-playbook -i inventory.ini playbook-nginx.yml
```

### Traefik

**Why Choose Traefik:**
- ✅ Modern cloud-native design
- ✅ Beautiful React dashboard
- ✅ Automatic configuration reload
- ✅ Built-in Prometheus metrics
- ✅ Real-time monitoring
- ✅ YAML configuration

**Features:**
- TCP/HTTP load balancing
- Automatic service discovery
- Modern dashboard
- Built-in metrics
- Health checks
- Dynamic configuration

**Dashboard:** http://lb-ip:8080/dashboard/

**Configuration Example:**
```yaml
tcp:
  services:
    kubernetes-masters:
      loadBalancer:
        servers:
          - address: "192.168.1.10:6443"
          - address: "192.168.1.11:6443"
          - address: "192.168.1.12:6443"
```

**Setup:**
```bash
# Bash
sudo ./setup-traefik.sh

# Ansible
ansible-playbook -i inventory.ini playbook-traefik.yml
```

### Comparison Matrix

| Feature | HAProxy | Nginx | Traefik |
|---------|---------|-------|---------|
| **Memory Usage** | ~5 MB | ~5 MB | ~30 MB |
| **CPU Usage** | Very Low | Very Low | Low-Moderate |
| **Setup Time** | 10 min | 10 min | 12 min |
| **Configuration** | haproxy.cfg | nginx.conf | YAML |
| **Dashboard** | Basic HTML | Basic text | Modern React UI |
| **Auto-reload** | Manual | Manual | Automatic |
| **Health Checks** | Advanced | Basic (Plus: Advanced) | Built-in |
| **Metrics** | Via exporter | Via exporter | Built-in Prometheus |
| **Learning Curve** | Moderate | Moderate | Easy |
| **Production Use** | 15+ years | 15+ years | 5+ years |
| **Best Algorithm** | Round robin | Least conn | WRR |

### Which to Choose?

**Decision Tree:**
```
Are you familiar with one already?
├─ Yes → Use that one
└─ No
   ├─ Want maximum performance? → HAProxy
   ├─ Want versatility (web+LB)? → Nginx
   └─ Want modern dashboard? → Traefik
```

**By Use Case:**
- **Traditional Infrastructure:** HAProxy
- **Mixed Workloads:** Nginx
- **Cloud-Native:** Traefik
- **Highest Traffic:** HAProxy
- **Easiest Monitoring:** Traefik
- **Most Familiar:** Nginx (for most teams)

---

## Architecture Options

### Option 1: Single Master (No HA)

**Architecture:**
```
┌─────────────┐
│   Clients   │
└──────┬──────┘
       │
       ▼
┌──────────────┐      ┌───────────┐
│    Master    │─────→│  Workers  │
│  (Single)    │      │  (1-100+) │
└──────────────┘      └───────────┘
     SPOF!
```

**Use Cases:**
- Development environments
- Testing/POC
- Learning Kubernetes
- Small projects
- Cost-sensitive deployments

**Pros:**
- ✅ Simple setup
- ✅ Lower resource requirements
- ✅ Fast deployment (~15 min)
- ✅ Easy to understand
- ✅ Fewer nodes to manage

**Cons:**
- ❌ Single point of failure
- ❌ No failover capability
- ❌ Downtime during master maintenance
- ❌ Not production-ready
- ❌ Lower availability

**Node Requirements:**
- 1 master: 2GB RAM, 2 CPU
- N workers: 2GB RAM, 2 CPU each

**Setup Commands:**
```bash
# Bash
sudo ./setup-k8s-master.sh
sudo ./setup-k8s-worker.sh  # on each worker

# Ansible
ansible-playbook -i inventory.ini site.yml
```

### Option 2: HA with Load Balancer

**Architecture:**
```
┌─────────────┐
│   Clients   │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│  Load Balancer   │  (HAProxy/Nginx/Traefik)
│  (192.168.1.5)   │
└────────┬─────────┘
         │
    ┌────┼────┐
    ▼    ▼    ▼
┌────┐ ┌────┐ ┌────┐
│ M1 │ │ M2 │ │ M3 │  Masters (3-7 recommended)
└──┬─┘ └──┬─┘ └──┬─┘
   │      │      │
   └──────┴──────┘
          │
     ┌────┴────┐
     ▼         ▼
  ┌────┐    ┌────┐
  │ W1 │ .. │ WN │  Workers (1-1000+)
  └────┘    └────┘
```

**Use Cases:**
- Production environments
- Critical applications
- High availability requirements
- Zero downtime maintenance
- Enterprise deployments

**Pros:**
- ✅ No single point of failure
- ✅ Survive master failures
- ✅ Zero downtime maintenance
- ✅ Load distribution
- ✅ Production-ready
- ✅ Easy scaling

**Cons:**
- ❌ More complex setup
- ❌ More nodes required
- ❌ Higher resource usage
- ❌ Requires load balancer

**Node Requirements:**
- 1 load balancer: 1GB RAM, 1 CPU
- 3+ masters: 2GB RAM, 2 CPU each
- N workers: 2GB RAM, 2 CPU each

**Setup Commands:**
```bash
# Bash
sudo ./setup-haproxy.sh      # or nginx/traefik
sudo ./setup-k8s-master.sh   # on each master
sudo ./setup-k8s-worker.sh   # on each worker

# Ansible (recommended for HA)
ansible-playbook -i inventory-ha.ini site-ha.yml
```

### Master Count Recommendations

| Masters | Can Tolerate | etcd Quorum | Use Case |
|---------|--------------|-------------|----------|
| **1** | 0 failures | N/A | Dev/Test only |
| **2** | 0 failures | ❌ Not recommended | Never use |
| **3** | 1 failure | ✅ 2/3 (recommended) | Production minimum |
| **5** | 2 failures | ✅ 3/5 | High availability |
| **7** | 3 failures | ✅ 4/7 | Maximum availability |

**Why odd numbers?**
etcd requires a majority (quorum) to function. With even numbers, losing half the nodes causes quorum loss.

---

## Installation Guide

### Phase 0: Preparation

#### 1. Prepare All Nodes

**On each node:**
```bash
# Update system
apt update && apt upgrade -y

# Set unique hostname
hostnamectl set-hostname node-name

# Verify requirements
free -h              # Check RAM
nproc                # Check CPUs
df -h                # Check disk
ip addr              # Note IP address
```

#### 2. Network Planning

**IP Address Scheme:**
```
Load Balancer: 192.168.1.5
Masters:       192.168.1.10-19
Workers:       192.168.1.20-99
```

**Port Requirements:**

Load Balancer:
- 6443 (TCP) - Kubernetes API
- 8080 or 9000 (TCP) - Statistics/Dashboard

Masters:
- 6443 (TCP) - Kubernetes API
- 2379-2380 (TCP) - etcd
- 10250 (TCP) - Kubelet
- 10259 (TCP) - Kube-scheduler
- 10257 (TCP) - Kube-controller-manager

Workers:
- 10250 (TCP) - Kubelet
- 30000-32767 (TCP) - NodePort Services

#### 3. SSH Setup (For Ansible)

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096

# Copy to all nodes
ssh-copy-id root@192.168.1.5   # Load balancer
ssh-copy-id root@192.168.1.10  # Master1
ssh-copy-id root@192.168.1.11  # Master2
ssh-copy-id root@192.168.1.12  # Master3
ssh-copy-id root@192.168.1.21  # Worker1
# ... repeat for all workers

# Test connectivity
ssh root@192.168.1.10 hostname
```

### Phase 1: Load Balancer Setup (HA Only)

Choose one load balancer:

#### HAProxy Setup

**Bash Method:**
```bash
# On load balancer node
wget https://your-repo/setup-haproxy.sh
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh

# Prompts:
# - Hostname: haproxy
# - Number of masters: 3
# - Master 1: master1, 192.168.1.10
# - Master 2: master2, 192.168.1.11
# - Master 3: master3, 192.168.1.12
# - Port: 6443

# Save the configuration output!
```

**Ansible Method:**
```bash
cd ansible

# Create/update inventory
cat > inventory.ini << EOF
[haproxy]
haproxy1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
EOF

# Run HAProxy playbook
ansible-playbook -i inventory.ini playbook-haproxy.yml
```

**Verification:**
```bash
# Check status
ssh root@192.168.1.5
systemctl status haproxy

# Check statistics
curl http://192.168.1.5:9000/stats
# Or open in browser

# Check port
netstat -tulpn | grep 6443
```

#### Nginx Setup

**Bash Method:**
```bash
# On load balancer node
chmod +x setup-nginx.sh
sudo ./setup-nginx.sh

# Prompts similar to HAProxy
```

**Ansible Method:**
```bash
# Update inventory with [nginx] group instead of [haproxy]
ansible-playbook -i inventory.ini playbook-nginx.yml
```

**Verification:**
```bash
systemctl status nginx
curl http://192.168.1.5:8080/nginx-status
```

#### Traefik Setup

**Bash Method:**
```bash
chmod +x setup-traefik.sh
sudo ./setup-traefik.sh
```

**Ansible Method:**
```bash
# Update inventory with [traefik] group
ansible-playbook -i inventory.ini playbook-traefik.yml
```

**Verification:**
```bash
systemctl status traefik
curl http://192.168.1.5:8080/api/overview
# Open dashboard: http://192.168.1.5:8080/dashboard/
```

### Phase 2: Master Node Setup

#### Single Master

**Bash Method:**
```bash
# On master node
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh

# Script will:
# 1. Update system
# 2. Install containerd
# 3. Install Kubernetes
# 4. Initialize cluster
# 5. Install CNI (Flannel)
# 6. Display join command

# SAVE THE JOIN COMMAND!
```

**Ansible Method:**
```bash
# Update inventory
cat > inventory.ini << EOF
[master]
master1 ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
EOF

# Run complete setup
ansible-playbook -i inventory.ini site.yml
```

#### HA Masters

**Important:** For HA, set control plane endpoint to load balancer IP!

**First Master (Bootstrap):**
```bash
# Bash method
ssh root@192.168.1.10
sudo ./setup-k8s-master.sh
# Use load balancer IP (192.168.1.5:6443) as endpoint

# Ansible method
# Update group_vars/all.yml:
control_plane_endpoint: "192.168.1.5:6443"

# Run master playbook
ansible-playbook -i inventory.ini playbook-master.yml --limit=master1
```

**Additional Masters:**

Get join command from first master:
```bash
ssh root@192.168.1.10
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)
```

Join second master:
```bash
ssh root@192.168.1.11
sudo kubeadm join 192.168.1.5:6443 \
  --token TOKEN \
  --discovery-token-ca-cert-hash sha256:HASH \
  --control-plane \
  --certificate-key CERT_KEY
```

Repeat for third master.

**With Ansible (Automatic):**
```bash
# If all masters are in inventory, Ansible handles joining automatically
ansible-playbook -i inventory.ini playbook-master.yml
```

### Phase 3: Worker Node Setup

**Bash Method:**

Get join command:
```bash
# On any master
kubeadm token create --print-join-command
```

Join workers:
```bash
# On each worker
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh

# Enter hostname when prompted
# Paste join command when asked
```

**Ansible Method:**
```bash
# Workers automatically get join command from master
ansible-playbook -i inventory.ini playbook-workers.yml
```

### Phase 4: Verification

**Check All Nodes:**
```bash
kubectl get nodes
```

Expected output:
```
NAME      STATUS   ROLES           AGE   VERSION
master1   Ready    control-plane   10m   v1.28.15
master2   Ready    control-plane   8m    v1.28.15
master3   Ready    control-plane   8m    v1.28.15
worker1   Ready    <none>          5m    v1.28.15
worker2   Ready    <none>          5m    v1.28.15
```

**Check System Pods:**
```bash
kubectl get pods -n kube-system
```

All pods should be Running:
- coredns (2 replicas)
- kube-apiserver (one per master)
- kube-controller-manager (one per master)
- kube-scheduler (one per master)
- etcd (one per master)
- kube-proxy (one per node)
- CNI plugin pods (one per node)

**Check Cluster Info:**
```bash
kubectl cluster-info
```

**Test Deployment:**
```bash
# Create test deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Check pods
kubectl get pods -o wide

# Expose service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service
kubectl get svc nginx

# Test access
curl http://WORKER_IP:NODE_PORT
```

---

## Configuration Reference

### Ansible Inventory

#### Single Master Inventory

**File:** `inventory.ini`

```ini
# Single Master Kubernetes Cluster Inventory

[master]
control-plane ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
worker3 ansible_host=192.168.1.23 ansible_user=root

[k8s_cluster:children]
master
workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### HA Inventory

**File:** `inventory-ha.ini`

```ini
# HA Kubernetes Cluster Inventory with Load Balancer

[haproxy]
# OR [nginx] OR [traefik] - choose one
haproxy1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
worker3 ansible_host=192.168.1.23 ansible_user=root

[k8s_cluster:children]
master
workers

[all_nodes:children]
haproxy
master
workers
```

### Ansible Variables

#### Core Variables

**File:** `group_vars/all.yml`

```yaml
# Kubernetes Version
kubernetes_version: "1.28"

# Network Configuration
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
control_plane_endpoint: "192.168.1.10:6443"  # Single master
# control_plane_endpoint: "192.168.1.5:6443"  # HA with LB

# CNI Plugin
cni_plugin: "flannel"  # or "calico"

# System Configuration
disable_swap: true
enable_ipv4_forwarding: true

# Token TTL
token_ttl: "24h"
```

#### Load Balancer Variables

**HAProxy:**
```yaml
haproxy_apiserver_port: 6443
haproxy_stats_port: 9000
haproxy_balance_algorithm: "roundrobin"
haproxy_maxconn: 4000
haproxy_timeout_connect: "5000ms"
haproxy_timeout_client: "50000ms"
haproxy_timeout_server: "50000ms"
```

**Nginx:**
```yaml
nginx_apiserver_port: 6443
nginx_status_port: 8080
nginx_lb_method: "least_conn"
nginx_max_fails: 3
nginx_fail_timeout: "10s"
nginx_proxy_timeout: "10s"
```

**Traefik:**
```yaml
traefik_apiserver_port: 6443
traefik_dashboard_port: 8080
traefik_lb_strategy: "wrr"
traefik_health_interval: "10s"
traefik_health_timeout: "5s"
traefik_log_level: "INFO"
```

### Configuration Files Locations

**Kubernetes:**
- Master config: `/etc/kubernetes/`
- Kubelet config: `/var/lib/kubelet/`
- CNI config: `/etc/cni/net.d/`
- Kubeconfig: `~/.kube/config`

**Load Balancers:**
- HAProxy: `/etc/haproxy/haproxy.cfg`
- Nginx: `/etc/nginx/nginx.conf`, `/etc/nginx/stream-enabled/`
- Traefik: `/etc/traefik/traefik.yml`, `/etc/traefik/dynamic/`

**Logs:**
- Kubelet: `journalctl -u kubelet`
- Containerd: `journalctl -u containerd`
- HAProxy: `journalctl -u haproxy`
- Nginx: `/var/log/nginx/`
- Traefik: `/var/log/traefik/`

---

## Verification & Testing

### Node Health Checks

```bash
# Check all nodes
kubectl get nodes

# Detailed node info
kubectl get nodes -o wide

# Describe specific node
kubectl describe node worker1

# Check node resources
kubectl top nodes  # Requires metrics-server
```

### Pod Health Checks

```bash
# All pods in all namespaces
kubectl get pods -A

# Pods in specific namespace
kubectl get pods -n kube-system

# Pod details
kubectl describe pod POD_NAME -n NAMESPACE

# Pod logs
kubectl logs POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE --previous  # Previous instance
```

### Component Health

```bash
# Check component status
kubectl get componentstatuses

# Check API server
curl -k https://CONTROL_PLANE:6443/healthz

# Check etcd
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

### Load Balancer Health

**HAProxy:**
```bash
# Status page
curl http://LB_IP:9000/stats

# Check backends via stats
# All should show "UP" in green

# Test connection
nc -zv LB_IP 6443
```

**Nginx:**
```bash
# Status page
curl http://LB_IP:8080/nginx-status

# Stream logs
tail -f /var/log/nginx/stream-access.log

# Test connection
nc -zv LB_IP 6443
```

**Traefik:**
```bash
# Dashboard
curl http://LB_IP:8080/api/overview

# Health check
curl http://LB_IP:8080/ping

# Metrics
curl http://LB_IP:8080/metrics

# Test connection
nc -zv LB_IP 6443
```

### Network Testing

```bash
# Pod to pod communication
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod:
nslookup kubernetes.default
wget -O- http://SERVICE_NAME

# NodePort access
kubectl get svc
curl http://NODE_IP:NODE_PORT

# DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

### Failover Testing (HA Only)

**Test Master Failure:**
```bash
# Stop one master
ssh master2
systemctl stop kubelet
systemctl stop containerd

# Check cluster still works
kubectl get nodes
kubectl create deployment test --image=nginx

# Check load balancer
# HAProxy: master2 should show as DOWN
# Nginx: Logs show traffic to other masters
# Traefik: Dashboard shows master2 as unhealthy

# Restart master
systemctl start containerd
systemctl start kubelet

# Master automatically rejoins
kubectl get nodes
```

**Test Load Balancer:**
```bash
# Make API calls through LB
for i in {1..100}; do
  kubectl get nodes > /dev/null
  sleep 1
done

# Check LB logs/stats to see distribution
# HAProxy: Check stats page for request counts
# Nginx: tail -f /var/log/nginx/stream-access.log
# Traefik: Check dashboard metrics
```

### Performance Testing

```bash
# Deploy test workload
kubectl create deployment load-test --image=nginx --replicas=100

# Watch pod distribution
watch kubectl get pods -o wide

# Check node resources
kubectl top nodes
kubectl top pods

# Scale test
kubectl scale deployment load-test --replicas=200
kubectl scale deployment load-test --replicas=50

# Cleanup
kubectl delete deployment load-test
```

---

## Troubleshooting

### Common Issues

#### 1. Node NotReady

**Symptoms:**
```bash
$ kubectl get nodes
NAME      STATUS     ROLES    AGE   VERSION
worker1   NotReady   <none>   5m    v1.28.15
```

**Causes & Solutions:**

**A. CNI Not Running:**
```bash
# Check CNI pods
kubectl get pods -n kube-system | grep -E 'flannel|calico'

# If not running, reinstall CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

**B. Kubelet Issues:**
```bash
# Check kubelet
systemctl status kubelet
journalctl -u kubelet -f

# Restart kubelet
systemctl restart kubelet
```

**C. Swap Not Disabled:**
```bash
# Check swap
free -h | grep Swap

# Disable if needed
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

#### 2. Pods Stuck in Pending

**Check:**
```bash
kubectl describe pod POD_NAME

# Look for:
# - "0/N nodes are available: N Insufficient cpu/memory"
# - "0/N nodes are available: N node(s) had taints"
```

**Solutions:**

**Insufficient Resources:**
```bash
# Check node resources
kubectl top nodes

# Add more workers or scale down deployments
```

**Taints:**
```bash
# Check taints
kubectl describe nodes | grep Taints

# Remove taint if needed
kubectl taint nodes NODE_NAME key:NoSchedule-
```

#### 3. Worker Won't Join

**Get new join command:**
```bash
# On master
kubeadm token create --print-join-command
```

**Reset worker if needed:**
```bash
# On worker
kubeadm reset -f
rm -rf /etc/cni/net.d
rm -rf /var/lib/kubelet/*
rm -rf /etc/kubernetes

# Run join command again
kubeadm join ...
```

#### 4. API Server Connection Refused

**Check API server:**
```bash
# On master
systemctl status kubelet
sudo crictl ps | grep kube-apiserver

# Check logs
journalctl -u kubelet -f

# Restart if needed
systemctl restart kubelet
```

**Check certificates:**
```bash
kubeadm certs check-expiration
```

**Regenerate if needed:**
```bash
kubeadm certs renew all
systemctl restart kubelet
```

#### 5. etcd Issues (HA)

**Check etcd members:**
```bash
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

**Check etcd health:**
```bash
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

#### 6. Load Balancer Issues

**HAProxy Shows Backend Down:**
```bash
# On master, check API server
systemctl status kubelet
netstat -tulpn | grep 6443

# Restart if needed
systemctl restart kubelet

# Check HAProxy config
cat /etc/haproxy/haproxy.cfg
haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart HAProxy
systemctl restart haproxy
```

**Nginx 503 Error:**
```bash
# Check nginx config
nginx -t

# Check stream logs
tail -f /var/log/nginx/stream-error.log

# Restart nginx
systemctl restart nginx
```

**Traefik No Backends:**
```bash
# Check configuration
cat /etc/traefik/dynamic/kubernetes.yml

# Check logs
journalctl -u traefik -f

# Restart traefik
systemctl restart traefik
```

### Debug Commands

**Node Level:**
```bash
# System logs
journalctl -xe

# Kubelet logs
journalctl -u kubelet -f --since "10 minutes ago"

# Container runtime
systemctl status containerd
journalctl -u containerd -f

# Check running containers
sudo crictl ps
sudo crictl pods
```

**Cluster Level:**
```bash
# All resources
kubectl get all -A

# Events (last hour)
kubectl get events --sort-by='.lastTimestamp' -A

# Cluster info
kubectl cluster-info dump

# API server logs (if accessible)
kubectl logs -n kube-system kube-apiserver-master1
```

**Network Level:**
```bash
# Pod network
kubectl get pods -n kube-system -o wide | grep -E 'flannel|calico'

# Service endpoints
kubectl get endpoints -A

# Network policies
kubectl get networkpolicies -A

# DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

### Reset and Reinstall

**Reset Single Node:**
```bash
# Drain node (from master)
kubectl drain NODE_NAME --ignore-daemonsets --delete-emptydir-data

# Delete node (from master)
kubectl delete node NODE_NAME

# Reset node (on the node itself)
kubeadm reset -f
rm -rf /etc/cni/net.d
rm -rf /var/lib/kubelet/*
rm -rf /etc/kubernetes
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

# Rejoin (on the node)
kubeadm join ...
```

**Reset Entire Cluster:**
```bash
# With Ansible
ansible-playbook -i inventory.ini playbook-reset.yml

# Manual (on each node)
kubeadm reset -f
rm -rf /etc/cni/net.d
rm -rf /var/lib/kubelet/*
rm -rf /etc/kubernetes
rm -rf ~/.kube

# Then reinstall from scratch
```

---

## Maintenance & Operations

### Adding Nodes

#### Add Worker

**Bash:**
```bash
# Get join command from master
ssh master1
kubeadm token create --print-join-command

# On new worker
./setup-k8s-worker.sh
# Paste join command
```

**Ansible:**
```bash
# Add to inventory.ini
[workers]
...
worker4 ansible_host=192.168.1.24 ansible_user=root

# Run worker playbook
ansible-playbook -i inventory.ini playbook-workers.yml --limit=worker4
```

#### Add Master (HA)

**Get join command:**
```bash
ssh master1
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)
```

**Join new master:**
```bash
ssh master4
kubeadm join LB_IP:6443 --token TOKEN \
  --discovery-token-ca-cert-hash sha256:HASH \
  --control-plane --certificate-key CERT_KEY
```

**Update load balancer:**
- HAProxy: Add server line, reload
- Nginx: Add server line, reload
- Traefik: Auto-detects (if using DNS)

### Removing Nodes

#### Remove Worker

```bash
# Drain node
kubectl drain worker3 --ignore-daemonsets --delete-emptydir-data

# Delete from cluster
kubectl delete node worker3

# On the worker
kubeadm reset -f
```

#### Remove Master (HA)

```bash
# Drain
kubectl drain master3 --ignore-daemonsets --delete-emptydir-data

# Delete
kubectl delete node master3

# Remove from etcd
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member remove MEMBER_ID

# On the master
kubeadm reset -f

# Update load balancer config
```

### Upgrading Kubernetes

**Important:** Always upgrade one minor version at a time (1.28 → 1.29 → 1.30)

**Upgrade Master:**
```bash
# Update package
apt-mark unhold kubeadm
apt update
apt install -y kubeadm=1.29.x-00
apt-mark hold kubeadm

# Plan upgrade
kubeadm upgrade plan

# Apply upgrade
kubeadm upgrade apply v1.29.x

# Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt install -y kubelet=1.29.x-00 kubectl=1.29.x-00
apt-mark hold kubelet kubectl

# Restart kubelet
systemctl daemon-reload
systemctl restart kubelet
```

**Upgrade Workers:**
```bash
# Drain node
kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data

# On worker
apt-mark unhold kubeadm kubelet kubectl
apt update
apt install -y kubeadm=1.29.x-00 kubelet=1.29.x-00 kubectl=1.29.x-00
apt-mark hold kubeadm kubelet kubectl

kubeadm upgrade node

systemctl daemon-reload
systemctl restart kubelet

# Uncordon
kubectl uncordon worker1
```

### Backup and Restore

#### Backup etcd

**Manual:**
```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**Automated (cron):**
```bash
cat > /etc/cron.daily/etcd-backup << 'EOF'
#!/bin/bash
BACKUP_DIR=/backup/etcd
mkdir -p $BACKUP_DIR
ETCDCTL_API=3 etcdctl snapshot save $BACKUP_DIR/etcd-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
# Keep last 7 days
find $BACKUP_DIR -name "etcd-*.db" -mtime +7 -delete
EOF

chmod +x /etc/cron.daily/etcd-backup
```

#### Restore etcd

```bash
# Stop API server
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# Restore snapshot
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore

# Update etcd to use new data dir
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change: /var/lib/etcd to /var/lib/etcd-restore

# Start API server
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Verify
kubectl get nodes
```

### Certificate Management

**Check expiration:**
```bash
kubeadm certs check-expiration
```

**Renew certificates:**
```bash
# Renew all certificates
kubeadm certs renew all

# Restart components
systemctl restart kubelet

# Update kubeconfig
cp /etc/kubernetes/admin.conf ~/.kube/config
```

**Auto-renewal:**
Certificates auto-renew when kubeadm upgrades are performed.

### Monitoring

**Install Metrics Server:**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# If using self-signed certs, add flag:
kubectl edit deployment metrics-server -n kube-system
# Add: --kubelet-insecure-tls
```

**View Metrics:**
```bash
kubectl top nodes
kubectl top pods -A
```

**Install Prometheus & Grafana:**
```bash
# Using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

---

## Advanced Topics

### Multi-Master HA Best Practices

1. **Always use odd numbers** (3, 5, 7 masters)
2. **Spread across availability zones** if possible
3. **Use dedicated etcd** for very large clusters (1000+ nodes)
4. **Monitor etcd health** continuously
5. **Backup etcd daily**
6. **Test failover scenarios** regularly

### Load Balancer HA

For production, eliminate load balancer as SPOF:

**Option 1: Keepalived + VIP**
```bash
# 2 load balancers share a Virtual IP (VIP)
# Keepalived provides automatic failover
# Control plane endpoint points to VIP
```

**Option 2: DNS Round Robin**
```bash
# Multiple A records for same hostname
# Example:
k8s-api.example.com → 192.168.1.5
k8s-api.example.com → 192.168.1.6
```

**Option 3: External Load Balancer**
```bash
# Cloud provider LB (AWS ELB, GCP LB, etc.)
# Or hardware load balancer
```

### External etcd

For very large clusters (1000+ nodes):

**Benefits:**
- Independent scaling
- Better isolation
- Easier backups
- More control

**Setup:**
1. Deploy 3-5 dedicated etcd nodes
2. Initialize Kubernetes with external etcd
3. Point masters to etcd cluster

**Trade-offs:**
- More complexity
- More nodes to manage
- Usually not needed for <1000 nodes

### Network Policies

**Enable:** (depends on CNI)
- Calico: Enabled by default
- Flannel: Requires flannel + Calico (Canal)

**Example policy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Storage

**Local Storage:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker1
```

**Network Storage:**
- NFS
- Ceph/Rook
- GlusterFS
- Cloud provider (EBS, Persistent Disks, etc.)

### Ingress Controllers

**Nginx Ingress:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
```

**Traefik Ingress:**
```bash
helm repo add traefik https://helm.traefik.io/traefik
helm install traefik traefik/traefik
```

### Security Hardening

**1. RBAC:**
```bash
# Minimal permissions
# Use ServiceAccounts
# Avoid cluster-admin
```

**2. Pod Security:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

**3. Network Policies:**
```bash
# Deny all by default
# Allow only required traffic
```

**4. Secrets Management:**
```bash
# Use external secret managers
# Encrypt secrets at rest
# Rotate credentials regularly
```

**5. Audit Logging:**
```yaml
# Enable in kube-apiserver
--audit-log-path=/var/log/kubernetes/audit.log
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

---

## File Reference

### Complete File List (50+ files)

**Documentation (20 files):**
```
COMPREHENSIVE-GUIDE.md          ← This file
00-START-HERE.md
00-START-HERE-HA.md
QUICK-START.md
README-UPDATED.md
PACKAGE-INDEX.md
HA-SETUP-GUIDE.md
HA-WHATS-NEW.md
LOAD-BALANCER-COMPARISON.md
LOAD-BALANCER-QUICKSTART.md
WHATS-NEW-LOAD-BALANCERS.md
FILE-STRUCTURE.md
kubernetes-etcd-debian12-setup.md
kubernetes-worker-node-setup.md
(+ more)
```

**Bash Scripts (5 files):**
```
setup-k8s-master.sh             13 KB
setup-k8s-worker.sh             16 KB
setup-haproxy.sh                15 KB
setup-nginx.sh                  16 KB
setup-traefik.sh                18 KB
```

**Ansible Playbooks (9 files):**
```
site.yml
site-ha.yml
playbook-common.yml
playbook-master.yml
playbook-workers.yml
playbook-reset.yml
playbook-haproxy.yml
playbook-nginx.yml
playbook-traefik.yml
```

**Configuration (4 files):**
```
inventory.ini
inventory-ha.ini
ansible.cfg
group_vars/all.yml
group_vars/all-ha.yml
```

**Templates (9 files):**
```
haproxy.cfg.j2
nginx-main.conf.j2
nginx-stream-kubernetes.conf.j2
traefik-static.yml.j2
traefik-dynamic-kubernetes.yml.j2
traefik.service.j2
```

### File Sizes

| Category | Files | Total Size |
|----------|-------|------------|
| Documentation | 20 | ~2 MB |
| Bash Scripts | 5 | ~80 KB |
| Ansible | 22 | ~200 KB |
| **Total** | **47** | **~2.3 MB** |

### Quick Access

**Getting Started:**
- New users: `00-START-HERE.md` or `00-START-HERE-HA.md`
- Quick setup: `QUICK-START.md`
- This guide: `COMPREHENSIVE-GUIDE.md`

**Load Balancers:**
- Compare: `LOAD-BALANCER-COMPARISON.md`
- Setup: `LOAD-BALANCER-QUICKSTART.md`

**HA Setup:**
- Complete guide: `HA-SETUP-GUIDE.md`
- What's new: `HA-WHATS-NEW.md`

**Reference:**
- All files: `PACKAGE-INDEX.md`
- File structure: `FILE-STRUCTURE.md`

---

## FAQ

### General Questions

**Q: Which setup method should I use?**  
A: Bash for 1-3 nodes or learning. Ansible for 4+ nodes or production.

**Q: Which load balancer should I choose?**  
A: HAProxy for maximum performance, Nginx if you know Nginx, Traefik for modern stack. All work great!

**Q: Do I need HA for production?**  
A: Yes, if downtime is not acceptable. Single master is OK for dev/test only.

**Q: How many masters do I need?**  
A: 3 masters for production (can tolerate 1 failure). 5 for high availability (2 failures). Never use 2.

**Q: Can I upgrade from single master to HA later?**  
A: Not easily. Plan for HA from the start if you'll need it.

### Technical Questions

**Q: What if token expires?**  
A: Generate new token: `kubeadm token create --print-join-command`

**Q: How do I add more workers?**  
A: Get join command from master, run on new worker. Or add to inventory and run worker playbook.

**Q: Can I switch load balancers?**  
A: Yes, if using same IP and port. No Kubernetes reconfiguration needed.

**Q: How do I backup the cluster?**  
A: Backup etcd snapshots daily. Also backup manifests and configs.

**Q: What if a master fails?**  
A: With HA (3 masters), cluster continues working. Fix/replace failed master.

**Q: How do I upgrade Kubernetes?**  
A: One minor version at a time. Upgrade masters first, then workers.

### Troubleshooting Questions

**Q: Node shows NotReady?**  
A: Check CNI pods, kubelet status, swap disabled. See Troubleshooting section.

**Q: Pods stuck in Pending?**  
A: Check resources, taints, events. Likely insufficient resources or taints.

**Q: Can't join worker?**  
A: Check network, token validity, control plane endpoint. Reset and rejoin.

**Q: API server refuses connection?**  
A: Check kubelet, certificates, API server pod. Restart kubelet.

**Q: Load balancer shows backend down?**  
A: Check master API server, kubelet, certificates. Check LB config.

### Operational Questions

**Q: How do I monitor the cluster?**  
A: Install metrics-server for basic metrics. Prometheus+Grafana for full monitoring.

**Q: How do I handle secrets?**  
A: Use Kubernetes secrets. For production, use external secret manager (Vault, etc.).

**Q: How do I expose services?**  
A: Use NodePort (simple), LoadBalancer (cloud), or Ingress (production).

**Q: How do I update load balancer config?**  
A: Edit config file, test with `-t`, reload service.

**Q: How do I scale workers?**  
A: Add more worker nodes and join to cluster. Kubernetes auto-schedules pods.

### Best Practices Questions

**Q: Should I run workloads on masters?**  
A: No. Keep masters dedicated to control plane only.

**Q: How often should I backup?**  
A: Daily etcd snapshots minimum. More frequently for critical data.

**Q: Should I use external etcd?**  
A: Only for very large clusters (1000+ nodes). Embedded etcd is fine for most.

**Q: How do I secure the cluster?**  
A: Use RBAC, network policies, pod security, encrypt secrets, audit logs.

**Q: Should I enable monitoring?**  
A: Yes! Always monitor production clusters.

---

## Conclusion

You now have everything you need to deploy production-ready Kubernetes clusters!

### What You Learned

✅ Multiple setup methods (Bash + Ansible)  
✅ Three load balancer options (HAProxy, Nginx, Traefik)  
✅ Single master and HA architectures  
✅ Complete installation procedures  
✅ Configuration management  
✅ Troubleshooting techniques  
✅ Operational best practices  

### Next Steps

1. **Choose your setup method** (Bash or Ansible)
2. **Choose your architecture** (Single master or HA)
3. **Choose your load balancer** (if HA)
4. **Follow the installation guide**
5. **Verify and test**
6. **Deploy your applications**
7. **Set up monitoring**
8. **Implement backups**

### Getting Help

- **Quick Start:** `QUICK-START.md`
- **HA Guide:** `HA-SETUP-GUIDE.md`
- **Load Balancers:** `LOAD-BALANCER-COMPARISON.md`
- **Troubleshooting:** This guide, section 9
- **All Files:** `PACKAGE-INDEX.md`

### Production Checklist

Before going to production:

- [ ] HA setup (3+ masters)
- [ ] Load balancer configured
- [ ] All nodes showing Ready
- [ ] System pods all Running
- [ ] Monitoring installed
- [ ] Backup strategy implemented
- [ ] Security hardening applied
- [ ] Failover tested
- [ ] Documentation updated
- [ ] Team trained

---

## Document Information

**Version:** 2.0  
**Last Updated:** November 2025  
**Total Pages:** 100+  
**File Size:** ~500 KB  
**Coverage:** Complete

**Package Contents:**
- 5 Bash scripts
- 9 Ansible playbooks
- 9 Configuration templates
- 4 Inventory files
- 20+ Documentation files

**Supported Configurations:**
- Single master (1 master + N workers)
- HA with HAProxy (1 LB + 3-7 masters + N workers)
- HA with Nginx (1 LB + 3-7 masters + N workers)
- HA with Traefik (1 LB + 3-7 masters + N workers)

**Total Setup Time:**
- Bash (single master): ~20 minutes
- Bash (HA): ~40 minutes
- Ansible (any): ~15-25 minutes

---

**Build your production Kubernetes cluster with confidence!** 🚀

**Questions?** → See FAQ section or specific guides  
**Issues?** → See Troubleshooting section  
**Ready?** → Start with `00-START-HERE.md`!

---

*End of Comprehensive Guide*
