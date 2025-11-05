# 🚀 Kubernetes HA Setup - START HERE!

## High Availability Kubernetes Cluster with HAProxy

### 🎯 What's New?

You now have **High Availability (HA)** setup options! This means your cluster can survive master node failures.

---

## 📊 Choose Your Setup Type

### Option 1: Single Master (Simple)
```
Client → Master → Workers
```
**When to use:** Testing, development, learning  
**Downtime if master fails:** Yes  
**Setup time:** 15-20 minutes  
**Files:** Use original setup scripts/playbooks

### Option 2: HA with HAProxy (Production)
```
Client → HAProxy → [Master1, Master2, Master3] → Workers
```
**When to use:** Production, critical workloads  
**Downtime if master fails:** No (automatic failover)  
**Setup time:** 20-25 minutes  
**Files:** Use HA-specific scripts/playbooks

---

## 🚦 Quick Decision Guide

| Criteria | Single Master | HA with HAProxy |
|----------|---------------|-----------------|
| **Environment** | Dev/Test | Production |
| **Downtime tolerance** | Acceptable | Not acceptable |
| **Budget** | Lower (fewer nodes) | Higher (more nodes) |
| **Complexity** | Simple | Moderate |
| **Maintenance** | Requires downtime | Zero downtime |

---

## 📦 HA Files Overview

### New HA Files

**Bash Scripts:**
- `setup-haproxy.sh` - HAProxy load balancer setup

**Ansible:**
- `ansible/site-ha.yml` - Complete HA setup orchestration
- `ansible/playbook-haproxy.yml` - HAProxy configuration
- `ansible/inventory-ha.ini` - HA inventory template
- `ansible/group_vars/all-ha.yml` - HA variables
- `ansible/templates/haproxy.cfg.j2` - HAProxy config template

**Documentation:**
- `HA-SETUP-GUIDE.md` - Complete HA setup guide

---

## ⚡ Quick Start - HA Setup

### Bash Method

```bash
# 1. Setup HAProxy
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh
# Note the control plane endpoint

# 2. Setup masters with HAProxy endpoint
sudo ./setup-k8s-master.sh
# Use HAProxy IP as endpoint

# 3. Join additional masters
# (see HA-SETUP-GUIDE.md for details)

# 4. Join workers
sudo ./setup-k8s-worker.sh
```

### Ansible Method (Recommended for HA)

```bash
cd ansible

# 1. Use HA inventory
cp inventory-ha.ini inventory.ini
nano inventory.ini  # Add your IPs

# 2. Use HA variables
cp group_vars/all-ha.yml group_vars/all.yml
nano group_vars/all.yml  # Set control_plane_endpoint

# 3. Run HA setup
ansible-playbook -i inventory.ini site-ha.yml
```

---

## 📚 Documentation Guide

### For Single Master Setup
→ **[00-START-HERE.md](00-START-HERE.md)** - Original start guide  
→ **[README-UPDATED.md](README-UPDATED.md)** - Complete documentation  
→ **[QUICK-START.md](QUICK-START.md)** - Quick reference

### For HA Setup
→ **[HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)** - Complete HA guide (START HERE!)  
→ **[README-UPDATED.md](README-UPDATED.md)** - Also covers HA  
→ **[PACKAGE-INDEX.md](PACKAGE-INDEX.md)** - File reference

---

## 🎯 Minimum Node Requirements

### Single Master
- 1 Master: 2GB RAM, 2 CPU
- 2+ Workers: 2GB RAM, 2 CPU each

### HA with HAProxy
- 1 HAProxy: 1GB RAM, 1 CPU
- 3 Masters: 2GB RAM, 2 CPU each
- 2+ Workers: 2GB RAM, 2 CPU each

---

## 🏗️ Architecture Comparison

### Single Master
```
┌─────────┐
│ Clients │
└────┬────┘
     │
     ▼
┌─────────┐     ┌─────────┐
│ Master  │────→│ Workers │
└─────────┘     └─────────┘
   SPOF!
```

### HA with HAProxy
```
┌─────────┐
│ Clients │
└────┬────┘
     │
     ▼
┌─────────┐
│ HAProxy │ (Load Balancer)
└────┬────┘
     │
     ├─────────┬─────────┐
     ▼         ▼         ▼
┌─────────┐┌─────────┐┌─────────┐
│Master 1 ││Master 2 ││Master 3 │
└────┬────┘└────┬────┘└────┬────┘
     │          │          │
     └──────────┴──────────┘
              │
              ▼
         ┌─────────┐
         │ Workers │
         └─────────┘
```

---

## ✅ Which Setup Should I Use?

### Use Single Master if:
- 🧪 Learning Kubernetes
- 💻 Development environment
- 🎯 Testing/Proof of concept
- 💰 Limited budget (fewer VMs)
- ⚡ Quick setup needed
- 📊 Small scale (< 10 nodes)

### Use HA with HAProxy if:
- 🏢 Production workloads
- 🔒 Critical applications
- 📈 High availability requirement
- 🔄 Zero downtime needed
- 👥 Multiple teams using cluster
- 📊 Medium to large scale (10+ nodes)

---

## 🚀 Next Steps

### Chosen Single Master?
1. Read: [00-START-HERE.md](00-START-HERE.md)
2. Follow: [QUICK-START.md](QUICK-START.md)
3. Deploy your first app

### Chosen HA with HAProxy?
1. Read: [HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)
2. Follow the complete HA setup
3. Test failover scenarios
4. Deploy production apps

---

## 🆘 Common Questions

### Q: Can I upgrade from single master to HA later?
**A:** Not easily. Better to start with HA if you plan to use it in production.

### Q: How many masters do I need?
**A:** 
- Development: 1
- Production: 3 (recommended)
- High availability: 5

### Q: Is HAProxy a single point of failure?
**A:** In basic setup, yes. For full HA, use 2 HAProxy nodes with keepalived (advanced).

### Q: What happens if one master fails in HA?
**A:** Cluster continues working. HAProxy routes traffic to healthy masters automatically.

### Q: Can I run workloads on master nodes?
**A:** Not recommended. Keep masters dedicated to control plane only.

---

## 📊 Setup Time Estimates

| Setup Type | Bash Method | Ansible Method |
|------------|-------------|----------------|
| **Single Master** | 20 minutes | 15 minutes |
| **HA (3 masters)** | 40 minutes | 20-25 minutes |

---

## 🎯 Recommended Path

### New to Kubernetes?
1. Start with **Single Master** using **Bash Scripts**
2. Learn Kubernetes basics
3. Later rebuild with HA for production

### Going to Production?
1. Start with **HA Setup** using **Ansible**
2. Use 3 masters + HAProxy
3. Test failover before deploying apps

---

## 📁 File Organization

```
kubernetes-setup/
├── 00-START-HERE-HA.md           ← You are here!
├── HA-SETUP-GUIDE.md             ← Complete HA guide
│
├── Bash Scripts/
│   ├── setup-haproxy.sh          ← NEW: HAProxy setup
│   ├── setup-k8s-master.sh
│   └── setup-k8s-worker.sh
│
└── ansible/
    ├── site-ha.yml               ← NEW: HA orchestration
    ├── playbook-haproxy.yml      ← NEW: HAProxy playbook
    ├── inventory-ha.ini          ← NEW: HA inventory
    ├── group_vars/all-ha.yml     ← NEW: HA variables
    └── templates/
        └── haproxy.cfg.j2        ← NEW: HAProxy config
```

---

## 🎉 Ready to Begin?

**For Single Master:**
→ Go to [00-START-HERE.md](00-START-HERE.md)

**For HA with HAProxy:**
→ Go to [HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)

---

**Build a resilient Kubernetes cluster! 🚀**
