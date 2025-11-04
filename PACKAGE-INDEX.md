# 📚 Kubernetes Setup - Complete Package Index

## 🎯 Start Here!

### New to Kubernetes?
👉 Read: **[QUICK-START.md](QUICK-START.md)**

### Want Full Documentation?
👉 Read: **[README-UPDATED.md](README-UPDATED.md)**

### Understand File Organization?
👉 Read: **[FILE-STRUCTURE.md](FILE-STRUCTURE.md)**

---

## 📦 Package Contents

### 📄 Documentation (5 files)

| File | Purpose | When to Read |
|------|---------|--------------|
| **README-UPDATED.md** | Complete guide for both methods | Before setup |
| **QUICK-START.md** | Fast track setup guide | Quick reference |
| **FILE-STRUCTURE.md** | File organization explained | Understanding structure |
| **kubernetes-etcd-debian12-setup.md** | Original detailed guide | Deep dive into etcd setup |
| **kubernetes-worker-node-setup.md** | Worker-specific details | Worker setup reference |

### 🔵 Bash Scripts (2 files)

| File | Purpose | Size | Runtime |
|------|---------|------|---------|
| **setup-k8s-master.sh** | Master node setup | 15 KB | 5-10 min |
| **setup-k8s-worker.sh** | Worker node setup | 12 KB | 3-5 min |

### 🟢 Ansible Playbooks (7 files)

| File | Purpose | Tasks | Runtime |
|------|---------|-------|---------|
| **ansible/site.yml** | Main orchestration | Imports all | 10-15 min |
| **ansible/playbook-common.yml** | Node preparation | 45+ | 5-7 min |
| **ansible/playbook-master.yml** | Master init | 25+ | 2-3 min |
| **ansible/playbook-workers.yml** | Workers join | 20+ | 2-3 min |
| **ansible/playbook-reset.yml** | Cleanup | 30+ | 3-5 min |
| **ansible/inventory.ini** | Node inventory | - | - |
| **ansible/group_vars/all.yml** | Configuration | - | - |
| **ansible/ansible.cfg** | Ansible config | - | - |

---

## 🚀 Quick Setup Paths

### Path A: Bash Scripts (Simple)

```bash
# 1. Master
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh

# 2. Workers
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh
```

**Time:** 20 minutes for 3 nodes  
**Docs:** [QUICK-START.md](QUICK-START.md)

### Path B: Ansible (Automated)

```bash
# 1. Setup
cd ansible
nano inventory.ini  # Add your IPs

# 2. Run
ansible-playbook -i inventory.ini site.yml
```

**Time:** 15 minutes for any nodes  
**Docs:** [README-UPDATED.md](README-UPDATED.md)

---

## 📖 Documentation Guide

### For Beginners
1. Start: [QUICK-START.md](QUICK-START.md)
2. If issues: [README-UPDATED.md](README-UPDATED.md) → Troubleshooting section

### For Production
1. Start: [README-UPDATED.md](README-UPDATED.md) → Method 2: Ansible
2. Customize: [ansible/group_vars/all.yml](ansible/group_vars/all.yml)
3. Reference: [FILE-STRUCTURE.md](FILE-STRUCTURE.md)

### For Deep Understanding
1. Read: [kubernetes-etcd-debian12-setup.md](kubernetes-etcd-debian12-setup.md)
2. Read: [kubernetes-worker-node-setup.md](kubernetes-worker-node-setup.md)
3. Explore: Bash script comments

---

## 🎯 Use Case Matrix

| Scenario | Use This | File/Command |
|----------|----------|--------------|
| **First time setup (1-3 nodes)** | Bash scripts | `setup-k8s-master.sh` + `setup-k8s-worker.sh` |
| **First time setup (4+ nodes)** | Ansible | `ansible-playbook -i inventory.ini site.yml` |
| **Add single worker** | Ansible | `ansible-playbook playbook-workers.yml --limit=worker3` |
| **Add multiple workers** | Ansible | Edit inventory + run `site.yml` |
| **Reset cluster** | Ansible | `ansible-playbook playbook-reset.yml` |
| **Learning K8s** | Bash scripts | Read scripts + run manually |
| **Production setup** | Ansible | Full playbook with custom vars |
| **Testing/Development** | Either | Choose based on preference |
| **CI/CD integration** | Ansible | Call playbooks from pipeline |

---

## 🔧 Configuration Files

### Must Edit
- ✅ **ansible/inventory.ini** - Add your node IPs and credentials

### Optional Edit
- ⚙️ **ansible/group_vars/all.yml** - Customize K8s settings
  - Change Kubernetes version
  - Select CNI plugin (Flannel/Calico)
  - Adjust network CIDRs
  - Modify token TTL

### Auto-Generated (Don't Edit)
- 📝 **ansible/ansible.log** - Execution logs
- 🔑 **ansible/k8s-join-command.txt** - Join token

---

## 📊 Feature Comparison

| Feature | Bash Scripts | Ansible |
|---------|--------------|---------|
| **Setup complexity** | ⭐⭐ Easy | ⭐⭐⭐ Moderate |
| **Execution speed** | ⭐⭐⭐ Fast per node | ⭐⭐⭐⭐ Fast overall |
| **Scalability** | ⭐⭐ Manual per node | ⭐⭐⭐⭐⭐ Highly scalable |
| **Error recovery** | ⭐⭐ Manual | ⭐⭐⭐⭐ Automatic retry |
| **Idempotency** | ⭐⭐ Partial | ⭐⭐⭐⭐⭐ Full |
| **Learning curve** | ⭐⭐⭐⭐⭐ Very easy | ⭐⭐⭐ Need Ansible basics |
| **Maintenance** | ⭐⭐ Manual updates | ⭐⭐⭐⭐ Centralized |
| **Team collaboration** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **Version control** | ⭐⭐⭐⭐ Easy | ⭐⭐⭐⭐⭐ Perfect |
| **Production ready** | ⭐⭐⭐⭐ Yes | ⭐⭐⭐⭐⭐ Yes |

---

## 🆘 Common Questions

### Q: Which method should I use?
**A:** 
- Learning/Testing/1-3 nodes → Bash scripts
- Production/4+ nodes/Automation → Ansible

### Q: Can I mix both methods?
**A:** Yes! Use bash for master, Ansible for workers, or vice versa.

### Q: How do I update Kubernetes version?
**A:** Edit `group_vars/all.yml` → `kubernetes_version: "1.29"` → Re-run playbook

### Q: What if token expires?
**A:** 
```bash
# Bash
kubeadm token create --print-join-command

# Ansible
ansible master -i inventory.ini -m shell -a "kubeadm token create --print-join-command"
```

### Q: How do I reset and start over?
**A:**
```bash
# Bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes /var/lib/kubelet /etc/cni

# Ansible
ansible-playbook -i inventory.ini playbook-reset.yml
```

### Q: Can I use this in production?
**A:** Yes! Both methods are production-ready. Ansible is recommended for scale.

### Q: What about high availability (HA)?
**A:** These scripts setup single master. For HA, you need multiple masters + load balancer (modify accordingly).

### Q: Which CNI should I use?
**A:** 
- Flannel: Simple, good for most use cases (default)
- Calico: Advanced networking, network policies

---

## 📁 Files by Category

### Essential Setup Files
```
setup-k8s-master.sh          # Bash: Master setup
setup-k8s-worker.sh          # Bash: Worker setup
ansible/site.yml             # Ansible: Complete setup
ansible/inventory.ini        # Ansible: Node inventory
```

### Documentation Files
```
README-UPDATED.md            # Complete guide
QUICK-START.md               # Quick reference
FILE-STRUCTURE.md            # File organization
PACKAGE-INDEX.md             # This file
```

### Configuration Files
```
ansible/group_vars/all.yml   # Kubernetes settings
ansible/ansible.cfg          # Ansible settings
```

### Playbook Files
```
ansible/playbook-common.yml  # Common setup
ansible/playbook-master.yml  # Master init
ansible/playbook-workers.yml # Workers join
ansible/playbook-reset.yml   # Cleanup
```

---

## 🎓 Learning Path

### Beginner (Day 1)
1. Read: [QUICK-START.md](QUICK-START.md)
2. Try: Bash scripts on test VMs
3. Learn: kubectl basics

### Intermediate (Day 2-3)
1. Read: [README-UPDATED.md](README-UPDATED.md)
2. Try: Ansible playbooks
3. Deploy: Sample applications

### Advanced (Week 1+)
1. Read: [kubernetes-etcd-debian12-setup.md](kubernetes-etcd-debian12-setup.md)
2. Customize: Playbooks and variables
3. Explore: HA setup, monitoring, backups

---

## 🔗 External Resources

### Official Documentation
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Ansible Docs](https://docs.ansible.com/)

### Networking
- [Flannel](https://github.com/flannel-io/flannel)
- [Calico](https://www.tigera.io/project-calico/)

### Container Runtime
- [containerd](https://containerd.io/docs/)

---

## 📋 Pre-Flight Checklist

Before starting, ensure:

### For Bash Scripts
- [ ] Debian 12 on all nodes
- [ ] Root/sudo access
- [ ] Network connectivity
- [ ] At least 2GB RAM, 2 CPUs per node

### Additional for Ansible
- [ ] Ansible installed on control machine
- [ ] Python 3 on all nodes
- [ ] SSH access configured
- [ ] SSH keys distributed (recommended)

---

## ⏱️ Time Estimates

| Task | Bash Method | Ansible Method |
|------|-------------|----------------|
| **Initial setup (3 nodes)** | 20 minutes | 15 minutes |
| **Add 5 workers** | +25 minutes | +5 minutes |
| **Add 10 workers** | +50 minutes | +7 minutes |
| **Reset cluster** | 15 minutes | 5 minutes |
| **Reconfigure** | Re-run scripts | Edit vars + re-run |

---

## 🎯 Next Steps After Setup

1. **Verify cluster**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

2. **Deploy test app**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl expose deployment nginx --port=80 --type=NodePort
   ```

3. **Install add-ons**
   - Metrics Server (monitoring)
   - Ingress Controller (HTTP routing)
   - Dashboard (web UI)

4. **Configure storage**
   - Set up persistent volumes
   - Install CSI driver

5. **Set up monitoring**
   - Prometheus + Grafana
   - Logging stack

6. **Implement backups**
   - etcd snapshots
   - Velero for application backups

---

## 📞 Support & Contribution

### Getting Help
- Check: [README-UPDATED.md](README-UPDATED.md) → Troubleshooting
- Review: Logs in `ansible/ansible.log`
- Search: Kubernetes documentation
- Ask: Community forums

### Contributing
Contributions welcome!
- Report bugs
- Suggest features
- Improve documentation
- Share your setup stories

---

## ✅ Quick Command Reference

### Bash Scripts
```bash
# Master
sudo ./setup-k8s-master.sh

# Worker  
sudo ./setup-k8s-worker.sh

# Get join command
kubeadm token create --print-join-command
```

### Ansible
```bash
# Complete setup
ansible-playbook -i inventory.ini site.yml

# Test connectivity
ansible all -i inventory.ini -m ping

# Reset cluster
ansible-playbook -i inventory.ini playbook-reset.yml

# Add worker
ansible-playbook -i inventory.ini playbook-workers.yml --limit=worker3
```

### kubectl
```bash
# View nodes
kubectl get nodes

# View pods
kubectl get pods -A

# Cluster info
kubectl cluster-info

# Deploy app
kubectl create deployment hello --image=nginx
```

---

## 🎉 Success Indicators

Your setup is successful when:

✅ All nodes show "Ready" status  
✅ All system pods are "Running"  
✅ Can create and scale deployments  
✅ Pods can communicate across nodes  
✅ kubectl commands work without errors  

---

**Questions?** Check the documentation files or start with [QUICK-START.md](QUICK-START.md)!

**Ready to begin?** Choose your method and get started! 🚀