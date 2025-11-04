# 📁 File Structure Overview

Complete guide to all files in the Kubernetes setup package.

```
kubernetes/
├── 📄 README-UPDATED.md              # Complete documentation (both methods)
├── 📄 QUICK-START.md                 # Fast setup guide
│
├── 🔵 Bash Scripts/
│   ├── setup-k8s-master.sh          # Master node setup script
│   └── setup-k8s-worker.sh          # Worker node setup script
│
└── 🟢 ansible/
    ├── ansible.cfg                   # Ansible configuration
    ├── inventory.ini                 # Cluster nodes inventory
    │
    ├── 📁 group_vars/
    │   └── c                   # Configuration variables
    │
    ├── 📋 Playbooks/
    │   ├── site.yml                  # Main orchestration playbook
    │   ├── playbook-common.yml       # Common node preparation
    │   ├── playbook-master.yml       # Master initialization
    │   ├── playbook-workers.yml      # Workers join cluster
    │   └── playbook-reset.yml        # Cleanup/reset cluster
    │
    └── 📝 Generated Files/
        ├── ansible.log               # Execution logs (auto-generated)
        └── k8s-join-command.txt      # Join command (auto-generated)
```

---

## 📄 Documentation Files

### README-UPDATED.md
**Purpose:** Complete documentation for both methods  
**Contains:**
- Feature comparison
- Detailed setup instructions
- Troubleshooting guide
- Advanced usage
- Next steps

**When to read:** Before starting setup

### QUICK-START.md
**Purpose:** Fast track setup guide  
**Contains:**
- TL;DR instructions
- Step-by-step quick guide
- Common issues & fixes

**When to read:** When you want to get started quickly

---

## 🔵 Bash Scripts

### setup-k8s-master.sh
**Purpose:** Initialize Kubernetes master/control-plane node  
**Size:** ~15 KB  
**Runtime:** 5-10 minutes  
**What it does:**
- Updates system
- Installs container runtime (containerd)
- Installs Kubernetes components
- Initializes cluster
- Installs CNI (Flannel)
- Generates join command

**Output files:**
- `/root/k8s-join-command.txt` - Join command for workers
- `/root/.kube/config` - kubectl configuration

**Usage:**
```bash
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh
```

### setup-k8s-worker.sh
**Purpose:** Prepare and join worker nodes to cluster  
**Size:** ~12 KB  
**Runtime:** 3-5 minutes  
**What it does:**
- Updates system
- Installs container runtime
- Installs Kubernetes components
- Joins cluster (optionally)

**Output files:**
- `/root/JOIN-INSTRUCTIONS.txt` - Reminder instructions

**Usage:**
```bash
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh
```

---

## 🟢 Ansible Files

### ansible.cfg
**Purpose:** Ansible configuration settings  
**Size:** ~1 KB  
**Configures:**
- Inventory location
- SSH settings
- Logging
- Output format
- Performance options

**Edit this if:**
- You want to change log location
- Need different SSH settings
- Want to adjust parallelism

### inventory.ini
**Purpose:** Define all cluster nodes  
**Size:** ~1 KB  
**Format:**
```ini
[master]
hostname ansible_host=IP ansible_user=USER

[workers]
worker1 ansible_host=IP ansible_user=USER
```

**Edit this:** Always! Add your actual node IPs and credentials

**Sections:**
- `[master]` - Control plane node(s)
- `[workers]` - Worker nodes
- `[k8s_cluster:children]` - All nodes group
- `[all:vars]` - Global variables

---

## 📁 group_vars/all.yml

**Purpose:** Centralized configuration variables  
**Size:** ~3 KB  
**Contains:**
- Kubernetes version
- Network CIDRs
- CNI plugin selection
- System parameters
- Package lists

**Common edits:**
```yaml
kubernetes_version: "1.28"           # Change K8s version
pod_network_cidr: "10.244.0.0/16"    # Change pod network
cni_plugin: "flannel"                # Change to "calico"
control_plane_endpoint: "IP:6443"    # Your master IP
```

**When to edit:**
- Changing Kubernetes version
- Using different CNI plugin
- Adjusting network ranges
- Modifying system settings

---

## 📋 Playbooks

### site.yml (Main Playbook)
**Purpose:** Orchestrate complete cluster setup  
**Size:** ~3 KB  
**Runtime:** 10-15 minutes  
**What it does:**
1. Imports playbook-common.yml
2. Imports playbook-master.yml
3. Imports playbook-workers.yml
4. Displays completion message

**Usage:**
```bash
ansible-playbook -i inventory.ini site.yml
```

**Run specific phase:**
```bash
ansible-playbook -i inventory.ini site.yml --tags=phase1
```

### playbook-common.yml
**Purpose:** Prepare all nodes (master + workers)  
**Size:** ~8 KB  
**Runtime:** 5-7 minutes  
**What it does:**
- Update system packages
- Configure hostnames
- Disable swap
- Load kernel modules
- Configure sysctl
- Install containerd
- Install Kubernetes components

**Tasks:** 45+ tasks  
**Handlers:** Restart containerd

**Run standalone:**
```bash
ansible-playbook -i inventory.ini playbook-common.yml
```

### playbook-master.yml
**Purpose:** Initialize master node  
**Size:** ~6 KB  
**Runtime:** 2-3 minutes  
**What it does:**
- Check if already initialized
- Run kubeadm init
- Configure kubectl
- Install CNI plugin
- Generate join command
- Verify cluster

**Tasks:** 25+ tasks  
**Output:** Join command saved locally and on master

**Run standalone:**
```bash
ansible-playbook -i inventory.ini playbook-master.yml
```

### playbook-workers.yml
**Purpose:** Join workers to cluster  
**Size:** ~5 KB  
**Runtime:** 2-3 minutes  
**What it does:**
- Check if already joined
- Read join command
- Join cluster
- Verify kubelet
- Label nodes
- Verify from master

**Tasks:** 20+ tasks  

**Run standalone:**
```bash
ansible-playbook -i inventory.ini playbook-workers.yml
```

**Add single worker:**
```bash
ansible-playbook -i inventory.ini playbook-workers.yml --limit=worker3
```

### playbook-reset.yml
**Purpose:** Complete cluster cleanup  
**Size:** ~7 KB  
**Runtime:** 3-5 minutes  
**What it does:**
- Drain nodes
- Reset kubeadm
- Remove packages (optional)
- Clean configuration
- Reset networking
- Remove repositories

**⚠️ WARNING:** This destroys the cluster!

**Tasks:** 30+ tasks

**Usage:**
```bash
# Reset entire cluster
ansible-playbook -i inventory.ini playbook-reset.yml

# Reset single node
ansible-playbook -i inventory.ini playbook-reset.yml --limit=worker1

# Reset and reboot
ansible-playbook -i inventory.ini playbook-reset.yml --tags=reboot
```

---

## 📝 Generated Files

### ansible.log
**Auto-generated:** Yes  
**Location:** `ansible/ansible.log`  
**Purpose:** Execution logs  
**Contains:**
- Task execution details
- Timing information
- Errors and warnings
- Host responses

**View logs:**
```bash
tail -f ansible.log
grep ERROR ansible.log
```

### k8s-join-command.txt
**Auto-generated:** Yes  
**Locations:**
- `ansible/k8s-join-command.txt` (local)
- `/root/k8s-join-command.txt` (master node)

**Purpose:** Store join command for workers  
**Format:**
```bash
kubeadm join IP:6443 --token TOKEN --discovery-token-ca-cert-hash sha256:HASH
```

**Regenerate if lost:**
```bash
# From master node
kubeadm token create --print-join-command

# Or with Ansible
ansible master -i inventory.ini -m shell -a "kubeadm token create --print-join-command"
```

---

## 🎯 File Usage by Scenario

### First Time Setup
1. Read: `README-UPDATED.md` or `QUICK-START.md`
2. Edit: `ansible/inventory.ini`
3. Review: `ansible/group_vars/all.yml`
4. Run: `ansible-playbook -i inventory.ini site.yml`

### Add Worker Node
1. Edit: `ansible/inventory.ini` (add new worker)
2. Run: `ansible-playbook -i inventory.ini playbook-workers.yml --limit=new-worker`

### Troubleshooting
1. Check: `ansible/ansible.log`
2. Read: `README-UPDATED.md` troubleshooting section

### Reset Cluster
1. Run: `ansible-playbook -i inventory.ini playbook-reset.yml`

### Customize Setup
1. Edit: `ansible/group_vars/all.yml`
2. Edit: Playbook files (advanced)

---

## 📊 File Dependencies

```
site.yml
  ├── requires: inventory.ini
  ├── requires: ansible.cfg
  ├── imports: playbook-common.yml
  ├── imports: playbook-master.yml
  └── imports: playbook-workers.yml

playbook-common.yml
  ├── requires: inventory.ini
  └── requires: group_vars/all.yml

playbook-master.yml
  ├── requires: inventory.ini
  ├── requires: group_vars/all.yml
  └── generates: k8s-join-command.txt

playbook-workers.yml
  ├── requires: inventory.ini
  ├── requires: group_vars/all.yml
  └── requires: k8s-join-command.txt

playbook-reset.yml
  ├── requires: inventory.ini
  └── requires: ansible.cfg
```

---

## 🔐 Security Considerations

### Files Containing Sensitive Data

| File | Sensitive Data | Protection |
|------|----------------|------------|
| `inventory.ini` | IP addresses, usernames | Use `.gitignore` |
| `k8s-join-command.txt` | Join token | `chmod 600`, expires 24h |
| `ansible.log` | Execution details | Review before sharing |
| `/root/.kube/config` | Cluster credentials | `chmod 600` |

### Recommended `.gitignore`
```
ansible/inventory.ini
ansible/ansible.log
ansible/k8s-join-command.txt
ansible/*.retry
```

---

## 📏 File Sizes

| File | Size | Type |
|------|------|------|
| `setup-k8s-master.sh` | ~15 KB | Bash |
| `setup-k8s-worker.sh` | ~12 KB | Bash |
| `site.yml` | ~3 KB | YAML |
| `playbook-common.yml` | ~8 KB | YAML |
| `playbook-master.yml` | ~6 KB | YAML |
| `playbook-workers.yml` | ~5 KB | YAML |
| `playbook-reset.yml` | ~7 KB | YAML |
| `inventory.ini` | ~1 KB | INI |
| `group_vars/all.yml` | ~3 KB | YAML |
| `ansible.cfg` | ~1 KB | INI |
| **Total** | **~60 KB** | - |

---

## ⚡ Quick Reference

### Must Edit Before Use
- ✅ `ansible/inventory.ini` - Add your node IPs

### Optional Configuration
- ⚙️ `ansible/group_vars/all.yml` - Customize settings

### Main Execution Files
- 🎯 Bash: `setup-k8s-master.sh`, `setup-k8s-worker.sh`
- 🎯 Ansible: `site.yml`

### Documentation
- 📖 Full docs: `README-UPDATED.md`
- ⚡ Quick start: `QUICK-START.md`
- 📁 This file: `FILE-STRUCTURE.md`

---

**Need help?** Check `README-UPDATED.md` for detailed documentation!