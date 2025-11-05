# Kubernetes Setup - Quick Reference Card

**Fast reference for all setup methods and configurations**

---

## 🎯 Choose Your Path

```
Single Master (Dev/Test)     HA with Load Balancer (Production)
        │                              │
        ├─ Bash Scripts               ├─ Choose Load Balancer:
        │  ├─ setup-k8s-master.sh     │  ├─ HAProxy (max performance)
        │  └─ setup-k8s-worker.sh     │  ├─ Nginx (versatile)
        │                              │  └─ Traefik (modern)
        └─ Ansible                     │
           └─ site.yml                 └─ Ansible (recommended)
                                          └─ site-ha.yml
```

---

## ⚡ Instant Commands

### Single Master Setup

```bash
# Bash
sudo ./setup-k8s-master.sh && sudo ./setup-k8s-worker.sh

# Ansible
ansible-playbook -i inventory.ini site.yml
```

### HA Setup with HAProxy

```bash
# Ansible (recommended)
ansible-playbook -i inventory.ini site-ha.yml

# Bash (manual)
sudo ./setup-haproxy.sh      # On LB node
sudo ./setup-k8s-master.sh   # On master nodes
sudo ./setup-k8s-worker.sh   # On worker nodes
```

### HA Setup with Nginx

```bash
# Ansible
ansible-playbook -i inventory.ini playbook-nginx.yml
ansible-playbook -i inventory.ini playbook-master.yml
ansible-playbook -i inventory.ini playbook-workers.yml

# Bash
sudo ./setup-nginx.sh        # On LB node
sudo ./setup-k8s-master.sh   # On master nodes
sudo ./setup-k8s-worker.sh   # On worker nodes
```

### HA Setup with Traefik

```bash
# Ansible
ansible-playbook -i inventory.ini playbook-traefik.yml
ansible-playbook -i inventory.ini playbook-master.yml
ansible-playbook -i inventory.ini playbook-workers.yml

# Bash
sudo ./setup-traefik.sh      # On LB node
sudo ./setup-k8s-master.sh   # On master nodes
sudo ./setup-k8s-worker.sh   # On worker nodes
```

---

## 📋 Load Balancer Comparison

| Feature | HAProxy | Nginx | Traefik |
|---------|---------|-------|---------|
| Memory | 5MB | 5MB | 30MB |
| Dashboard | http://IP:9000/stats | http://IP:8080/nginx-status | http://IP:8080/dashboard/ |
| Auto-reload | ❌ | ❌ | ✅ |
| Best for | Production | Versatile | Modern |

---

## 🔧 Essential Commands

### Cluster Management

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Check cluster info
kubectl cluster-info

# Get join command
kubeadm token create --print-join-command

# Get join command for control plane
kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)
```

### Node Operations

```bash
# Drain node
kubectl drain NODE --ignore-daemonsets --delete-emptydir-data

# Delete node
kubectl delete node NODE

# Uncordon node
kubectl uncordon NODE

# Label node
kubectl label nodes NODE role=worker

# Taint node
kubectl taint nodes NODE key=value:NoSchedule
```

### Load Balancer Checks

```bash
# HAProxy
systemctl status haproxy
curl http://LB_IP:9000/stats

# Nginx
systemctl status nginx
curl http://LB_IP:8080/nginx-status
tail -f /var/log/nginx/stream-access.log

# Traefik
systemctl status traefik
curl http://LB_IP:8080/api/overview
curl http://LB_IP:8080/ping
# Dashboard: http://LB_IP:8080/dashboard/
```

### Troubleshooting

```bash
# Kubelet logs
journalctl -u kubelet -f

# Pod logs
kubectl logs POD_NAME -n NAMESPACE

# Describe pod
kubectl describe pod POD_NAME

# Events
kubectl get events --sort-by='.lastTimestamp'

# Check component status
kubectl get componentstatuses

# Reset node
kubeadm reset -f
rm -rf /etc/cni/net.d /var/lib/kubelet/* /etc/kubernetes
```

---

## 📁 Important Files

### Configuration

```
/etc/kubernetes/admin.conf          # Admin kubeconfig
~/.kube/config                      # User kubeconfig
/etc/kubernetes/manifests/          # Static pod manifests
/etc/haproxy/haproxy.cfg           # HAProxy config
/etc/nginx/nginx.conf              # Nginx config
/etc/traefik/traefik.yml           # Traefik config
```

### Logs

```
journalctl -u kubelet              # Kubelet logs
journalctl -u containerd           # Container runtime
journalctl -u haproxy              # HAProxy logs
/var/log/nginx/stream-access.log  # Nginx stream logs
/var/log/traefik/traefik.log      # Traefik logs
```

---

## 🔍 Quick Diagnostics

### Check Cluster Health

```bash
kubectl get nodes                           # All nodes Ready?
kubectl get pods -n kube-system            # All pods Running?
kubectl get componentstatuses              # All components Healthy?
kubectl top nodes                          # Resource usage (requires metrics-server)
```

### Check etcd (HA only)

```bash
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

### Test Deployment

```bash
# Create test
kubectl create deployment test --image=nginx --replicas=3

# Check
kubectl get pods -o wide

# Expose
kubectl expose deployment test --port=80 --type=NodePort

# Get port
kubectl get svc test

# Test
curl http://WORKER_IP:NODE_PORT

# Cleanup
kubectl delete deployment test
kubectl delete svc test
```

---

## 🚀 Common Tasks

### Add Worker

```bash
# Get join command
ssh master1 'kubeadm token create --print-join-command'

# On new worker
./setup-k8s-worker.sh
# Paste join command when prompted
```

### Add Master (HA)

```bash
# Get join command
ssh master1 'kubeadm token create --print-join-command --certificate-key \
  $(kubeadm init phase upload-certs --upload-certs | tail -1)'

# On new master
sudo kubeadm join LB_IP:6443 --token TOKEN \
  --discovery-token-ca-cert-hash sha256:HASH \
  --control-plane --certificate-key CERT_KEY

# Update load balancer config with new master IP
```

### Scale Deployment

```bash
kubectl scale deployment NAME --replicas=5
```

### Update Image

```bash
kubectl set image deployment/NAME CONTAINER=IMAGE:TAG
```

### Rollback

```bash
kubectl rollout undo deployment/NAME
```

### Backup etcd

```bash
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### Restore etcd

```bash
ETCDCTL_API=3 etcdctl snapshot restore backup.db --data-dir=/var/lib/etcd-restore
# Update etcd manifest to use new data dir
```

---

## 📊 Port Reference

### Load Balancer

- 6443 (TCP) - Kubernetes API

### Masters

- 6443 (TCP) - API Server
- 2379-2380 (TCP) - etcd
- 10250 (TCP) - Kubelet
- 10259 (TCP) - Scheduler
- 10257 (TCP) - Controller Manager

### Workers

- 10250 (TCP) - Kubelet
- 30000-32767 (TCP) - NodePort Services

### Monitoring

- 9000 (TCP) - HAProxy stats
- 8080 (TCP) - Nginx status / Traefik dashboard

---

## 💾 Inventory Templates

### Single Master

```ini
[master]
master1 ansible_host=192.168.1.10 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root

[k8s_cluster:children]
master
workers
```

### HA with HAProxy

```ini
[haproxy]
lb1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
```

### HA with Nginx

```ini
[nginx]
lb1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
```

### HA with Traefik

```ini
[traefik]
lb1 ansible_host=192.168.1.5 ansible_user=root

[master]
master1 ansible_host=192.168.1.10 ansible_user=root
master2 ansible_host=192.168.1.11 ansible_user=root
master3 ansible_host=192.168.1.12 ansible_user=root

[workers]
worker1 ansible_host=192.168.1.21 ansible_user=root
worker2 ansible_host=192.168.1.22 ansible_user=root
```

---

## 🛠️ Variables Reference

### Core Variables

```yaml
kubernetes_version: "1.28"
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
control_plane_endpoint: "192.168.1.5:6443"  # LB IP for HA
cni_plugin: "flannel"  # or "calico"
```

### HAProxy Variables

```yaml
haproxy_apiserver_port: 6443
haproxy_stats_port: 9000
haproxy_balance_algorithm: "roundrobin"
```

### Nginx Variables

```yaml
nginx_apiserver_port: 6443
nginx_status_port: 8080
nginx_lb_method: "least_conn"
```

### Traefik Variables

```yaml
traefik_apiserver_port: 6443
traefik_dashboard_port: 8080
traefik_lb_strategy: "wrr"
```

---

## 🎯 Decision Trees

### Architecture Choice

```
Production?
├─ Yes → HA (3+ masters)
└─ No → Single master

Masters?
├─ 3 → Tolerate 1 failure
├─ 5 → Tolerate 2 failures
└─ 7 → Tolerate 3 failures
```

### Load Balancer Choice

```
Performance priority?
├─ Yes → HAProxy

Know Nginx?
├─ Yes → Nginx

Want modern tools?
├─ Yes → Traefik

Can't decide?
└─ HAProxy (safest)
```

### Setup Method Choice

```
Nodes count?
├─ 1-3 → Bash scripts OK
└─ 4+ → Use Ansible

Production?
├─ Yes → Use Ansible
└─ No → Either OK

Learning?
└─ Use Bash (educational)
```

---

## 📖 Documentation Quick Links

- **[COMPREHENSIVE-GUIDE.md](COMPREHENSIVE-GUIDE.md)** - Complete guide (100+ pages)
- **[00-START-HERE.md](00-START-HERE.md)** - Single master start
- **[00-START-HERE-HA.md](00-START-HERE-HA.md)** - HA start
- **[LOAD-BALANCER-COMPARISON.md](LOAD-BALANCER-COMPARISON.md)** - Compare LBs
- **[HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)** - HA guide
- **[PACKAGE-INDEX.md](PACKAGE-INDEX.md)** - All files

---

## ⚡ One-Liner Setups

```bash
# Single master - Ansible
cd ansible && ansible-playbook -i inventory.ini site.yml

# HA with HAProxy - Ansible
cd ansible && ansible-playbook -i inventory.ini site-ha.yml

# Single master - Bash (master)
wget URL/setup-k8s-master.sh && chmod +x setup-k8s-master.sh && sudo ./setup-k8s-master.sh

# Single master - Bash (worker)
wget URL/setup-k8s-worker.sh && chmod +x setup-k8s-worker.sh && sudo ./setup-k8s-worker.sh

# HAProxy LB - Bash
wget URL/setup-haproxy.sh && chmod +x setup-haproxy.sh && sudo ./setup-haproxy.sh

# Nginx LB - Bash
wget URL/setup-nginx.sh && chmod +x setup-nginx.sh && sudo ./setup-nginx.sh

# Traefik LB - Bash
wget URL/setup-traefik.sh && chmod +x setup-traefik.sh && sudo ./setup-traefik.sh
```

---

## 🆘 Emergency Commands

```bash
# Restart everything
systemctl restart kubelet containerd

# Check everything
kubectl get nodes && kubectl get pods -A && kubectl get svc

# Reset everything
ansible-playbook -i inventory.ini playbook-reset.yml

# Emergency etcd backup
ETCDCTL_API=3 etcdctl snapshot save /tmp/emergency-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Drain all workers (emergency maintenance)
kubectl get nodes -o name | grep worker | xargs -I {} kubectl drain {} --ignore-daemonsets --delete-emptydir-data
```

---

## 🔐 Security Checklist

```bash
# [ ] Firewall configured
# [ ] SSH keys only (no passwords)
# [ ] Root login disabled (after setup)
# [ ] RBAC enabled (default)
# [ ] Network policies configured
# [ ] Secrets encrypted at rest
# [ ] Regular backups configured
# [ ] Monitoring enabled
# [ ] Certificate expiry monitoring
# [ ] Audit logging enabled
```

---

## 📊 Health Check Commands

```bash
# Quick health check
kubectl get nodes && \
kubectl get pods -n kube-system && \
kubectl get componentstatuses

# Full health check
kubectl cluster-info && \
kubectl get nodes -o wide && \
kubectl get pods -A && \
kubectl top nodes

# Load balancer health
# HAProxy
curl -s http://LB_IP:9000/stats | grep -E 'master[0-9]'

# Nginx
systemctl is-active nginx && curl -s http://LB_IP:8080/nginx-status

# Traefik
systemctl is-active traefik && curl -s http://LB_IP:8080/ping
```

---

**Save this card for quick reference!** 📌

*Last Updated: November 2025*
