# 🚀 Kubernetes Quick Start Guide

## Choose Your Path

### 🔵 Bash Scripts (Simple & Direct)
**Best for:** 1-3 nodes, learning, manual control  
**Time:** 20 minutes for 3 nodes  
**Requires:** Just SSH access

### 🟢 Ansible (Automated & Scalable)
**Best for:** 4+ nodes, production, automation  
**Time:** 15 minutes for any number of nodes  
**Requires:** Ansible + SSH keys

---

# PATH 1: Bash Scripts ⚡

## Step 1: Master Node (5-10 min)

```bash
chmod +x setup-k8s-master.sh
sudo ./setup-k8s-master.sh
```

💾 **Save the join command** from output!

## Step 2: Worker Nodes (3-5 min each)

```bash
chmod +x setup-k8s-worker.sh
sudo ./setup-k8s-worker.sh
# Enter hostname: worker1
# Join now? y
# Paste join command
```

## Step 3: Verify

```bash
kubectl get nodes
```

---

# PATH 2: Ansible 🤖

## Step 1: Install Ansible (2 min)

```bash
sudo apt install ansible
```

## Step 2: Setup SSH Keys (3 min)

```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id root@<master-ip>
ssh-copy-id root@<worker-ip>
```

## Step 3: Configure Inventory (2 min)

Edit `ansible/inventory.ini`:
```ini
[master]
control-plane ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
```

## Step 4: Run Setup (10-15 min)

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml
```

## Step 5: Verify

```bash
ssh root@<master-ip> kubectl get nodes
```

---

# ✅ Success Checklist

- [ ] All nodes show "Ready" status
- [ ] All system pods are "Running"
- [ ] Can create test deployment
- [ ] kubectl commands work

---

# 🆘 Quick Fixes

### Token Expired?
```bash
kubeadm token create --print-join-command
```

### Node NotReady?
```bash
kubectl get pods -n kube-system | grep flannel
```

### Reset Node?
```bash
sudo kubeadm reset -f
```

---

**Ready?** Pick your path and get started! 🎉