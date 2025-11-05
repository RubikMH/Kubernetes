# High Availability Kubernetes Setup with HAProxy

Complete guide for setting up a production-ready, highly available Kubernetes cluster using HAProxy as the API server load balancer.

## 📋 Table of Contents

- [What is High Availability (HA)?](#what-is-high-availability-ha)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Bash Script Method](#bash-script-method)
- [Ansible Method](#ansible-method)
- [Verification](#verification)
- [Testing HA](#testing-ha)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## What is High Availability (HA)?

High Availability means your Kubernetes cluster can continue operating even if one or more components fail. 

### Single Master (No HA)
```
[Clients] → [Master] → [Workers]
            (Single Point of Failure)
```
**Problem:** If master fails, entire cluster becomes unavailable.

### HA with HAProxy
```
[Clients] → [HAProxy] → [Master1]
                     → [Master2]  → [Workers]
                     → [Master3]
```
**Solution:** If one master fails, HAProxy routes traffic to healthy masters.

### Benefits of HA

✅ **No Single Point of Failure** - Multiple masters ensure availability  
✅ **Zero Downtime** - Cluster remains operational during master failures  
✅ **Load Distribution** - API requests distributed across masters  
✅ **Production Ready** - Meets production reliability requirements  
✅ **Easy Maintenance** - Update masters one at a time without downtime  

---

## Architecture Overview

### Cluster Components

```
┌─────────────────────────────────────────────────────────┐
│                     Clients / kubectl                    │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  HAProxy Load Balancer                   │
│                  (192.168.1.5:6443)                     │
│  • Distributes API requests                             │
│  • Health checks masters                                │
│  • Provides statistics                                  │
└──┬────────────────┬─────────────────┬──────────────────┘
   │                │                 │
   ▼                ▼                 ▼
┌──────────┐  ┌──────────┐   ┌──────────┐
│ Master 1 │  │ Master 2 │   │ Master 3 │
│   :6443  │  │   :6443  │   │   :6443  │
├──────────┤  ├──────────┤   ├──────────┤
│ API Svr  │  │ API Svr  │   │ API Svr  │
│ etcd     │  │ etcd     │   │ etcd     │
│Scheduler │  │Scheduler │   │Scheduler │
│Ctrl Mgr  │  │Ctrl Mgr  │   │Ctrl Mgr  │
└────┬─────┘  └────┬─────┘   └────┬─────┘
     │             │              │
     └─────────────┴──────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   ┌─────────┐           ┌─────────┐
   │Worker 1 │           │Worker 2 │
   │         │    ...    │         │
   │ Pods    │           │ Pods    │
   └─────────┘           └─────────┘
```

### Node Requirements

| Node Type | Count | RAM | CPU | Role |
|-----------|-------|-----|-----|------|
| **HAProxy** | 1-2 | 1GB | 1 | Load balancer |
| **Master** | 3+ | 2GB | 2 | Control plane |
| **Worker** | 2+ | 2GB | 2 | Run workloads |

**Note:** Always use odd number of masters (1, 3, 5, 7) for etcd quorum.

### Why 3 Masters?

| Masters | Can Tolerate | Quorum | Recommendation |
|---------|--------------|--------|----------------|
| 1 | 0 failures | N/A | Development only |
| 2 | 0 failures | ❌ Not recommended | Can't maintain quorum |
| **3** | **1 failure** | ✅ 2/3 needed | **Recommended minimum** |
| 5 | 2 failures | ✅ 3/5 needed | High availability |
| 7 | 3 failures | ✅ 4/7 needed | Very high availability |

---

## Prerequisites

### Hardware Requirements

- **HAProxy node:** 1GB RAM, 1 CPU, 20GB disk
- **Master nodes:** 2GB RAM, 2 CPUs, 50GB disk (each)
- **Worker nodes:** 2GB RAM, 2 CPUs, 50GB disk (each)

### Software Requirements

- Debian 12 (Bookworm) on all nodes
- SSH access to all nodes
- Root or sudo access
- Unique hostname per node
- Network connectivity between all nodes

### Network Requirements

**IP Planning Example:**
```
HAProxy:  192.168.1.5
Master 1: 192.168.1.10
Master 2: 192.168.1.11
Master 3: 192.168.1.12
Worker 1: 192.168.1.21
Worker 2: 192.168.1.22
```

**Ports Required:**

HAProxy:
- 6443 (TCP) - Kubernetes API
- 9000 (TCP) - Statistics page
- 8080 (TCP) - Health check

Masters:
- 6443 (TCP) - Kubernetes API
- 2379-2380 (TCP) - etcd
- 10250-10259 (TCP) - Kubelet, scheduler, controller

Workers:
- 10250 (TCP) - Kubelet
- 30000-32767 (TCP) - NodePort services

---

## Quick Start

### Using Ansible (Recommended)

```bash
# 1. Setup inventory
cd ansible
cp inventory-ha.ini inventory.ini
nano inventory.ini  # Add your node IPs

# 2. Update configuration
nano group_vars/all-ha.yml  # Set control_plane_endpoint

# 3. Run complete setup
ansible-playbook -i inventory.ini site-ha.yml

# 4. Verify
ssh root@master1 kubectl get nodes
```

**Time:** ~15-20 minutes

### Using Bash Scripts

```bash
# 1. Setup HAProxy
scp setup-haproxy.sh root@haproxy:~/
ssh root@haproxy
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh
# Note the control plane endpoint

# 2. Setup first master
ssh root@master1
sudo ./setup-k8s-master.sh
# Use HAProxy IP as endpoint when prompted

# 3. Join additional masters
# (requires manual certificate copying - see detailed guide)

# 4. Join workers
ssh root@worker1
sudo ./setup-k8s-worker.sh
```

**Time:** ~30-40 minutes

---

## Detailed Setup

### Phase 1: HAProxy Setup

#### Bash Method

```bash
# On HAProxy node
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh

# Answer prompts:
# - Hostname: haproxy
# - Number of masters: 3
# - Master 1: master1, 192.168.1.10
# - Master 2: master2, 192.168.1.11
# - Master 3: master3, 192.168.1.12
# - HAProxy port: 6443
```

#### Ansible Method

```bash
# Edit inventory
nano ansible/inventory-ha.ini

# Add HAProxy section:
[haproxy]
haproxy1 ansible_host=192.168.1.5 ansible_user=root

# Run HAProxy playbook
cd ansible
ansible-playbook -i inventory-ha.ini playbook-haproxy.yml
```

#### Verify HAProxy

```bash
# Check status
ssh root@haproxy
systemctl status haproxy

# View configuration
cat /etc/haproxy/haproxy.cfg

# Check statistics page
# Open browser: http://192.168.1.5:9000/stats
# Username: admin
# Password: (shown in setup output)
```

### Phase 2: Master Setup

#### First Master (Bootstrap)

**Bash Method:**
```bash
ssh root@master1

# Run master setup
sudo ./setup-k8s-master.sh

# When kubeadm init runs, it will use:
# --control-plane-endpoint=192.168.1.5:6443
# --upload-certs
```

**Ansible Method:**
```bash
# Update group_vars/all-ha.yml:
control_plane_endpoint: "192.168.1.5:6443"

# Run playbook
ansible-playbook -i inventory-ha.ini playbook-master.yml --limit master1
```

#### Additional Masters (Join)

**Get Join Command:**
```bash
# On first master
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | grep -vw -e certificate -e Namespace)
```

**Join Second Master:**
```bash
ssh root@master2

# Run the join command from above, but add --control-plane
sudo kubeadm join 192.168.1.5:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:hash... \
  --control-plane \
  --certificate-key certificate-key-here
```

**Repeat for Third Master:**
```bash
ssh root@master3
# Run same join command
```

**With Ansible:**
```bash
# Ansible handles this automatically if configured in inventory
ansible-playbook -i inventory-ha.ini playbook-master.yml
```

### Phase 3: Worker Setup

Same as non-HA setup:

```bash
# Get worker join command from any master
ssh root@master1
kubeadm token create --print-join-command

# On each worker
ssh root@worker1
sudo kubeadm join 192.168.1.5:6443 --token... --discovery-token-ca-cert-hash...
```

---

## Bash Script Method

### Complete Setup Steps

```bash
# 1. HAProxy Setup
scp setup-haproxy.sh root@192.168.1.5:~/
ssh root@192.168.1.5
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh
# Save the configuration output
exit

# 2. First Master
scp setup-k8s-master.sh root@192.168.1.10:~/
ssh root@192.168.1.10
chmod +x setup-k8s-master.sh
# Edit script to use: --control-plane-endpoint=192.168.1.5:6443
sudo ./setup-k8s-master.sh
# Save join commands (both worker and master)
exit

# 3. Second Master
ssh root@192.168.1.11
# Use master join command from step 2
sudo kubeadm join 192.168.1.5:6443 --token... --control-plane --certificate-key...
exit

# 4. Third Master
ssh root@192.168.1.12
# Use same master join command
sudo kubeadm join 192.168.1.5:6443 --token... --control-plane --certificate-key...
exit

# 5. Workers
for worker in worker1 worker2 worker3; do
  scp setup-k8s-worker.sh root@$worker:~/
  ssh root@$worker
  chmod +x setup-k8s-worker.sh
  sudo ./setup-k8s-worker.sh
  # Use worker join command
  exit
done

# 6. Verify
ssh root@192.168.1.10
kubectl get nodes
kubectl get pods -A
```

---

## Ansible Method

### Configuration Files

**inventory-ha.ini:**
```ini
[haproxy]
haproxy1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
worker3 ansible_host=192.168.1.23 ansible_user=root
```

**group_vars/all-ha.yml:**
```yaml
control_plane_endpoint: "192.168.1.5:6443"
enable_haproxy: true
haproxy_apiserver_port: 6443
haproxy_stats_port: 9000
```

### Run Complete Setup

```bash
cd ansible
cp inventory-ha.ini inventory.ini
cp group_vars/all-ha.yml group_vars/all.yml

# Test connectivity
ansible all -i inventory.ini -m ping

# Run complete setup
ansible-playbook -i inventory.ini site-ha.yml

# Time: 15-20 minutes
```

### Run Step by Step

```bash
# Phase 0: HAProxy
ansible-playbook -i inventory.ini site-ha.yml --tags=phase0

# Phase 1: Common
ansible-playbook -i inventory.ini site-ha.yml --tags=phase1

# Phase 2: Masters
ansible-playbook -i inventory.ini site-ha.yml --tags=phase2

# Phase 3: Workers
ansible-playbook -i inventory.ini site-ha.yml --tags=phase3
```

---

## Verification

### Check All Nodes

```bash
ssh root@master1
kubectl get nodes -o wide
```

Expected output:
```
NAME      STATUS   ROLES           AGE   VERSION    INTERNAL-IP
master1   Ready    control-plane   10m   v1.28.15   192.168.1.10
master2   Ready    control-plane   8m    v1.28.15   192.168.1.11
master3   Ready    control-plane   8m    v1.28.15   192.168.1.12
worker1   Ready    <none>          5m    v1.28.15   192.168.1.21
worker2   Ready    <none>          5m    v1.28.15   192.168.1.22
worker3   Ready    <none>          5m    v1.28.15   192.168.1.23
```

### Check System Pods

```bash
kubectl get pods -n kube-system
```

All pods should be "Running":
- kube-apiserver (on each master)
- etcd (on each master)
- kube-scheduler (on each master)
- kube-controller-manager (on each master)
- coredns
- kube-proxy (on all nodes)
- CNI plugin (flannel/calico) (on all nodes)

### Check HAProxy

```bash
ssh root@haproxy
systemctl status haproxy
```

View statistics:
```bash
# Open in browser
http://192.168.1.5:9000/stats
```

Check backend servers - all should be "UP" and green.

### Test API Access Through HAProxy

```bash
# From any node
curl -k https://192.168.1.5:6443/healthz
# Should return: ok

# With kubectl
kubectl --server=https://192.168.1.5:6443 get nodes
```

---

## Testing HA

### Test Master Failure

```bash
# Stop master2
ssh root@master2
systemctl stop kubelet
systemctl stop containerd
# Or just power off the node

# Check cluster still works
ssh root@master1
kubectl get nodes
kubectl create deployment nginx --image=nginx
kubectl get pods

# HAProxy statistics should show master2 as DOWN
# but cluster continues operating

# Restart master2
ssh root@master2
systemctl start containerd
systemctl start kubelet

# master2 automatically rejoins
```

### Test HAProxy Failure

⚠️ **Important:** In basic setup, HAProxy is still a single point of failure.

For full HA, you need:
1. Two HAProxy nodes
2. Keepalived for virtual IP (VIP)
3. Point control_plane_endpoint to VIP

**With basic setup:**
- If HAProxy fails, API becomes unavailable
- Existing pods continue running
- No new operations possible until HAProxy recovers

### Test API Load Distribution

```bash
# Watch HAProxy logs
ssh root@haproxy
journalctl -u haproxy -f

# From another terminal, make many API calls
for i in {1..100}; do
  kubectl get nodes > /dev/null
done

# HAProxy logs show requests distributed across masters
```

---

## Troubleshooting

### HAProxy Shows Master as DOWN

**Check master API server:**
```bash
ssh root@master1
systemctl status kube-apiserver
netstat -tulpn | grep 6443
```

**Check certificates:**
```bash
kubeadm certs check-expiration
```

**Restart kubelet:**
```bash
systemctl restart kubelet
```

### Cannot Join Additional Masters

**Get new certificate key:**
```bash
# On first master
kubeadm init phase upload-certs --upload-certs
# Use the certificate-key shown
```

**New join command:**
```bash
kubeadm token create --print-join-command
# Add: --control-plane --certificate-key <key>
```

### etcd Cluster Unhealthy

**Check etcd on each master:**
```bash
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

### HAProxy Returns 503

**Cause:** No healthy backend servers

**Solution:**
```bash
# Check all masters are running
for master in master1 master2 master3; do
  ssh root@$master systemctl status kubelet
done

# Restart HAProxy
ssh root@haproxy
systemctl restart haproxy
```

---

## Maintenance

### Adding a Master

```bash
# 1. Update inventory-ha.ini
[master]
master4 ansible_host=192.168.1.13 ansible_user=root

# 2. Get join command
ssh root@master1
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)

# 3. Join new master
ssh root@master4
sudo kubeadm join 192.168.1.5:6443 ... --control-plane --certificate-key...

# 4. HAProxy automatically detects new master
# No HAProxy reconfiguration needed if using DNS
# Or manually add to HAProxy config
```

### Removing a Master

```bash
# 1. Drain node
kubectl drain master3 --ignore-daemonsets --delete-emptydir-data

# 2. Delete from cluster
kubectl delete node master3

# 3. Reset node
ssh root@master3
kubeadm reset

# 4. Remove from HAProxy (if needed)
ssh root@haproxy
nano /etc/haproxy/haproxy.cfg
# Comment out or remove master3 line
systemctl reload haproxy
```

### Updating HAProxy Config

```bash
ssh root@haproxy

# Edit config
nano /etc/haproxy/haproxy.cfg

# Test config
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload (no downtime)
systemctl reload haproxy
```

### Upgrading Kubernetes

Follow official upgrade docs, but:
1. Upgrade one master at a time
2. HAProxy keeps cluster available
3. Test thoroughly before upgrading all masters

---

## Best Practices

✅ **DO:**
- Use 3 or 5 masters (odd numbers)
- Monitor HAProxy statistics regularly
- Test failover scenarios regularly
- Keep backups of etcd
- Use separate HAProxy node (don't colocate with master)
- Document your configuration
- Set up monitoring (Prometheus)

❌ **DON'T:**
- Use 2 masters (can't maintain quorum)
- Skip testing
- Ignore HAProxy logs
- Modify HAProxy config without testing
- Run workloads on masters

---

## Production Recommendations

### For Production Use:

1. **Multiple HAProxy nodes with Keepalived**
   - 2 HAProxy nodes
   - Keepalived for VIP
   - Eliminates HAProxy as single point of failure

2. **External etcd cluster**
   - Separate etcd nodes
   - Better isolation
   - Independent scaling

3. **Monitoring**
   - Prometheus + Grafana
   - HAProxy exporter
   - Alert on master/HAProxy failures

4. **Backups**
   - Automated etcd snapshots
   - Test restore procedures
   - Off-site backup storage

5. **Security**
   - Firewall rules
   - Private network for cluster communication
   - Certificate rotation
   - Regular security updates

---

## Summary

**Single Master:**
```
Client → Master → Workers
         (SPOF)
```

**HA with HAProxy:**
```
Client → HAProxy → [Master1, Master2, Master3] → Workers
         (Load Balance + Health Check)
```

**Benefits:**
- ✅ Survive master failures
- ✅ Zero downtime maintenance
- ✅ Production ready
- ✅ Better performance

**Trade-offs:**
- Additional complexity
- More resources required
- More nodes to manage

---

**Ready for HA?** Start with the Ansible method for easiest setup! 🚀
