# 🚀 Kubernetes Cluster Setup - START HERE!

## Welcome! You have everything you need to set up a production-ready Kubernetes cluster.

---

## 📚 Step 1: Choose Your Documentation

### 🎯 Quick Start (5 minutes read)
**→ [QUICK-START.md](QUICK-START.md)**
- TL;DR instructions
- Fast setup guide
- Perfect for getting started quickly

### 📖 Complete Guide (15 minutes read)
**→ [README-UPDATED.md](README-UPDATED.md)**
- Detailed instructions for both methods
- Troubleshooting guide
- Advanced usage
- Production recommendations

### 📦 Package Overview
**→ [PACKAGE-INDEX.md](PACKAGE-INDEX.md)**
- All files explained
- Use case matrix
- Command reference

---

## 🎯 Step 2: Choose Your Method

### Method A: Bash Scripts ⚡
**Best for:** 1-3 nodes, learning, quick setup

**Files to use:**
- `setup-k8s-master.sh` - Run on master node
- `setup-k8s-worker.sh` - Run on worker nodes

**Time:** ~20 minutes for 3 nodes

**Start with:** [QUICK-START.md](QUICK-START.md) → Bash Scripts section

### Method B: Ansible Playbooks 🤖
**Best for:** 4+ nodes, production, automation

**Files to use:**
- `ansible/inventory.ini` - Edit with your node IPs
- `ansible/site.yml` - Main playbook

**Time:** ~15 minutes for any number of nodes

**Start with:** [README-UPDATED.md](README-UPDATED.md) → Method 2: Ansible

---

## ⚡ Quick Start Commands

### Bash Method
```bash
# Master
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh

# Worker  
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh
```

### Ansible Method
```bash
# 1. Edit inventory
cd ansible
nano inventory.ini

# 2. Run setup
ansible-playbook -i inventory.ini site.yml
```

---

## 📋 Prerequisites Checklist

- [ ] Debian 12 on all nodes
- [ ] Minimum 2GB RAM, 2 CPUs per node
- [ ] Root or sudo access
- [ ] Network connectivity between nodes
- [ ] For Ansible: SSH keys set up

---

## 📁 File Organization

```
📦 Kubernetes Setup Package
│
├── 📄 00-START-HERE.md          ← You are here!
├── 📄 QUICK-START.md            ← Fast setup guide
├── 📄 README-UPDATED.md         ← Complete documentation
├── 📄 PACKAGE-INDEX.md          ← All files explained
│
├── 🔵 Bash Scripts
│   ├── setup-k8s-master.sh
│   └── setup-k8s-worker.sh
│
└── 🟢 Ansible
    ├── site.yml                 ← Main playbook
    ├── inventory.ini            ← Edit this!
    ├── playbook-common.yml
    ├── playbook-master.yml
    ├── playbook-workers.yml
    ├── playbook-reset.yml
    └── group_vars/all.yml       ← Configuration
```

---

## 🎯 Your First Steps

### If you want to START IMMEDIATELY:
1. **Read:** [QUICK-START.md](QUICK-START.md) (5 min)
2. **Choose:** Bash or Ansible method
3. **Run:** Follow the commands
4. **Verify:** `kubectl get nodes`

### If you want to UNDERSTAND FIRST:
1. **Read:** [README-UPDATED.md](README-UPDATED.md) (15 min)
2. **Review:** [PACKAGE-INDEX.md](PACKAGE-INDEX.md)
3. **Plan:** Your cluster architecture
4. **Execute:** With confidence

---

## 🆘 Need Help?

- **Setup issues?** → Check [README-UPDATED.md](README-UPDATED.md) Troubleshooting section
- **File questions?** → See [PACKAGE-INDEX.md](PACKAGE-INDEX.md)
- **Quick tips?** → Use [QUICK-START.md](QUICK-START.md)

---

## ✅ Success Looks Like

After setup, you should see:

```bash
$ kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   10m   v1.28.15
worker1         Ready    <none>          5m    v1.28.15
worker2         Ready    <none>          5m    v1.28.15
```

---

## 🎉 Ready to Begin?

**Pick your path:**

- 🎯 **Quick Setup:** [QUICK-START.md](QUICK-START.md)
- 📖 **Full Guide:** [README-UPDATED.md](README-UPDATED.md)
- 📦 **Explore Files:** [PACKAGE-INDEX.md](PACKAGE-INDEX.md)

**Let's build your Kubernetes cluster!** 🚀