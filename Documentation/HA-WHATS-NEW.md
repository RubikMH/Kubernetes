# HAProxy Integration - What's New

## Summary of HA Additions

This document summarizes all the new files and features added for High Availability (HA) Kubernetes setup with HAProxy load balancer.

---

## 🆕 New Files Created

### Bash Scripts (1 file)
1. **setup-haproxy.sh** (15 KB)
   - Interactive HAProxy setup script
   - Configures load balancer for Kubernetes API servers
   - Generates statistics page with credentials
   - Creates configuration file at /etc/haproxy/haproxy.cfg

### Ansible Playbooks (5 files)

1. **ansible/site-ha.yml** (4 KB)
   - Main orchestration playbook for HA setup
   - Runs HAProxy, master, and worker setup in order
   - Includes verification and validation steps

2. **ansible/playbook-haproxy.yml** (6 KB)
   - Complete HAProxy installation and configuration
   - Generates random statistics password
   - Validates configuration before applying
   - Creates health check endpoints

3. **ansible/inventory-ha.ini** (3 KB)
   - Sample inventory for HA cluster
   - Includes [haproxy] group definition
   - Multiple master node examples
   - Deployment scenario documentation

4. **ansible/group_vars/all-ha.yml** (5 KB)
   - HA-specific variables
   - HAProxy configuration options
   - Control plane endpoint settings
   - Detailed comments and recommendations

5. **ansible/templates/haproxy.cfg.j2** (2 KB)
   - Jinja2 template for HAProxy configuration
   - Automatic backend server generation
   - Statistics page configuration
   - Health check endpoint

### Documentation (2 files)

1. **HA-SETUP-GUIDE.md** (25 KB)
   - Complete HA setup guide
   - Architecture diagrams
   - Step-by-step instructions
   - Troubleshooting section
   - Testing procedures
   - Maintenance guide

2. **00-START-HERE-HA.md** (5 KB)
   - Quick start guide for HA
   - Decision matrix (single vs HA)
   - Architecture comparison
   - File organization
   - Quick commands

---

## 🎯 What is HAProxy Setup?

HAProxy acts as a load balancer in front of multiple Kubernetes master nodes, providing:

### Key Features

✅ **High Availability** - Survive master node failures  
✅ **Load Balancing** - Distribute API requests across masters  
✅ **Health Checking** - Automatic detection of failed masters  
✅ **Zero Downtime** - Maintenance without cluster downtime  
✅ **Statistics** - Real-time monitoring dashboard  
✅ **Production Ready** - Battle-tested load balancer

### Architecture

```
Before HA (Single Master):
Client → Master (SPOF) → Workers

After HA (with HAProxy):
Client → HAProxy → [Master1, Master2, Master3] → Workers
              ↓
         Load Balance & Health Check
```

---

## 📋 How to Use

### Quick Start - HA Setup

#### Method 1: Bash Scripts

```bash
# 1. Setup HAProxy
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh

# 2. Note the control plane endpoint shown
# 3. Use that endpoint when setting up masters
```

#### Method 2: Ansible (Recommended)

```bash
# 1. Use HA inventory
cd ansible
cp inventory-ha.ini inventory.ini
nano inventory.ini  # Add your IPs

# 2. Use HA variables
cp group_vars/all-ha.yml group_vars/all.yml
nano group_vars/all.yml  # Set control_plane_endpoint

# 3. Run HA setup
ansible-playbook -i inventory.ini site-ha.yml
```

---

## 🔧 Configuration Changes Required

### For Bash Method

**No changes to existing scripts required!**

Just run HAProxy setup first, then use the HAProxy IP when initializing the cluster.

### For Ansible Method

1. **Use HA inventory:**
   ```bash
   cp inventory-ha.ini inventory.ini
   ```

2. **Update control plane endpoint in group_vars/all.yml:**
   ```yaml
   control_plane_endpoint: "192.168.1.5:6443"  # HAProxy IP
   ```

3. **Use HA site playbook:**
   ```bash
   ansible-playbook -i inventory.ini site-ha.yml
   ```

---

## 📊 File Comparison

| Aspect | Single Master | HA with HAProxy |
|--------|---------------|-----------------|
| **Bash Scripts** | 2 files | 3 files (+1 HAProxy) |
| **Ansible Playbooks** | 5 files | 10 files (+5 HA) |
| **Documentation** | 4 guides | 6 guides (+2 HA) |
| **Nodes Required** | 1 master + workers | 1 HAProxy + 3 masters + workers |
| **Setup Time** | 15-20 min | 20-25 min |
| **Complexity** | Simple | Moderate |

---

## 🎓 Key Concepts

### Control Plane Endpoint

**Critical setting** - the address clients use to reach the API server.

**Single Master:**
```yaml
control_plane_endpoint: "192.168.1.10:6443"  # Master IP
```

**HA with HAProxy:**
```yaml
control_plane_endpoint: "192.168.1.5:6443"   # HAProxy IP
```

This must be:
- Set before cluster initialization
- Stable (never change after setup)
- Reachable from all nodes

### etcd Quorum

**Why odd numbers of masters?**

etcd requires a majority (quorum) to operate:

| Masters | Quorum | Can Tolerate Failures |
|---------|--------|----------------------|
| 1 | 1 (100%) | 0 ❌ |
| 2 | 2 (50%+1) | 0 ❌ Not recommended |
| **3** | **2 (66%)** | **1 ✅ Recommended** |
| 5 | 3 (60%) | 2 ✅ |
| 7 | 4 (57%) | 3 ✅ |

### HAProxy Backend Checks

HAProxy continuously checks master health:

```
Master Status in HAProxy:
- GREEN (UP): Master is healthy, receiving traffic
- RED (DOWN): Master failed health check, no traffic
- YELLOW (MAINT): Master in maintenance mode
```

---

## 🔍 What Gets Installed

### HAProxy Node

**Software:**
- HAProxy 2.x
- netcat (for health checks)

**Configuration:**
- `/etc/haproxy/haproxy.cfg` - Main config
- `/root/haproxy-config.txt` - Setup info

**Services:**
- Port 6443: API server proxy
- Port 9000: Statistics page
- Port 8080: Health check endpoint

### Master Nodes (No Changes)

Same as single master setup:
- Kubernetes components (kubeadm, kubelet, kubectl)
- containerd
- etcd (embedded)

But configured to use HAProxy endpoint instead of self.

---

## 🚦 Setup Flow

### Single Master Setup Flow
```
1. Install Kubernetes → 2. Initialize Cluster → 3. Join Workers
```

### HA Setup Flow with HAProxy
```
1. Setup HAProxy → 2. Install Kubernetes on all nodes → 
3. Initialize First Master → 4. Join Additional Masters → 5. Join Workers
```

### Ansible Automation
```
Phase 0: HAProxy (playbook-haproxy.yml)
Phase 1: Common Setup (playbook-common.yml)
Phase 2: Masters (playbook-master.yml)
Phase 3: Workers (playbook-workers.yml)
```

---

## ✅ Verification Checklist

After HA setup, verify:

- [ ] HAProxy is running: `systemctl status haproxy`
- [ ] Statistics page accessible: http://haproxy-ip:9000/stats
- [ ] All masters show as UP in HAProxy stats
- [ ] All master nodes show Ready: `kubectl get nodes`
- [ ] All system pods running: `kubectl get pods -A`
- [ ] Can access API through HAProxy: `curl -k https://haproxy-ip:6443/healthz`
- [ ] Failover test: Stop one master, cluster still works

---

## 🔧 Customization Options

### HAProxy Configuration Variables

```yaml
# Port configuration
haproxy_apiserver_port: 6443
haproxy_stats_port: 9000
haproxy_health_check_port: 8080

# Load balancing
haproxy_balance_algorithm: roundrobin  # or leastconn, source

# Timeouts
haproxy_timeout_connect: 5000ms
haproxy_timeout_client: 50000ms
haproxy_timeout_server: 50000ms

# Connection limits
haproxy_maxconn: 4000
```

### Balance Algorithms

- **roundrobin**: Even distribution (default, recommended)
- **leastconn**: Least connections (good for long-lived connections)
- **source**: Client IP-based (same client → same server)

---

## 📈 Scaling

### Adding Masters

```bash
# Get join command
ssh master1
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)

# Join new master
ssh master4
sudo kubeadm join haproxy-ip:6443 ... --control-plane --certificate-key...

# HAProxy automatically detects new master
# (if using DNS, otherwise update HAProxy config)
```

### Removing Masters

```bash
# Drain and delete
kubectl drain master3 --ignore-daemonsets
kubectl delete node master3

# Reset node
ssh master3
kubeadm reset

# Update HAProxy config if needed
```

---

## 🛡️ Production Best Practices

### For Production HA:

1. **Multiple HAProxy Nodes**
   - Use 2 HAProxy nodes
   - Implement keepalived for VIP
   - Eliminates HAProxy as SPOF

2. **Monitoring**
   - HAProxy exporter for Prometheus
   - Alert on master failures
   - Monitor backend health

3. **Backups**
   - Automated etcd snapshots
   - Test restore procedures
   - Off-site backup storage

4. **Security**
   - Firewall rules
   - Private network for cluster
   - TLS everywhere
   - Regular updates

5. **Testing**
   - Regular failover drills
   - Chaos engineering
   - Load testing

---

## 📊 Resource Requirements

### Minimum for HA

| Component | Count | RAM | CPU | Disk | Total |
|-----------|-------|-----|-----|------|-------|
| HAProxy | 1 | 1GB | 1 | 20GB | 1GB RAM |
| Masters | 3 | 2GB | 2 | 50GB | 6GB RAM |
| Workers | 2 | 2GB | 2 | 50GB | 4GB RAM |
| **Total** | **6** | | | | **11GB RAM** |

### Recommended for Production

| Component | Count | RAM | CPU | Disk | Total |
|-----------|-------|-----|-----|------|-------|
| HAProxy | 2 | 2GB | 2 | 20GB | 4GB RAM |
| Masters | 3-5 | 4GB | 4 | 100GB | 12-20GB RAM |
| Workers | 5+ | 4GB | 4 | 100GB | 20GB+ RAM |
| **Total** | **10+** | | | | **36GB+ RAM** |

---

## 🔗 Related Documentation

### Core Guides
- **[00-START-HERE-HA.md](00-START-HERE-HA.md)** - HA quick start
- **[HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)** - Complete HA guide
- **[README-UPDATED.md](README-UPDATED.md)** - All methods documentation

### Setup Files
- **[setup-haproxy.sh](setup-haproxy.sh)** - HAProxy bash script
- **[ansible/site-ha.yml](ansible/site-ha.yml)** - HA Ansible playbook
- **[ansible/inventory-ha.ini](ansible/inventory-ha.ini)** - HA inventory template

### Original Guides
- **[00-START-HERE.md](00-START-HERE.md)** - Single master start
- **[QUICK-START.md](QUICK-START.md)** - Quick reference
- **[PACKAGE-INDEX.md](PACKAGE-INDEX.md)** - All files index

---

## 🎯 Quick Command Reference

### HAProxy Management

```bash
# Status
systemctl status haproxy

# Logs
journalctl -u haproxy -f

# Reload config (no downtime)
systemctl reload haproxy

# Restart
systemctl restart haproxy

# Statistics
# Open: http://haproxy-ip:9000/stats
```

### Cluster Management

```bash
# Check nodes
kubectl get nodes

# Check from HAProxy perspective
curl -k https://haproxy-ip:6443/healthz

# Generate master join command
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)
```

### Testing

```bash
# Test failover
systemctl stop kubelet  # on one master

# Check cluster still works
kubectl get nodes

# Restart master
systemctl start kubelet
```

---

## 🎉 Summary

### What You Get with HA

✅ Production-ready Kubernetes cluster  
✅ Survive master node failures  
✅ Zero-downtime maintenance  
✅ Load balanced API requests  
✅ Real-time monitoring dashboard  
✅ Automatic health checking  
✅ Easy to scale (add/remove masters)  

### Investment

📊 **More nodes:** +1 HAProxy, +2 masters  
⏱️ **More time:** +5-10 minutes setup  
🎓 **More complexity:** Moderate (well documented)  
💰 **More cost:** +3 VMs  
🎯 **More reliability:** Priceless for production  

---

**Ready for High Availability?** Start with [HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)! 🚀
