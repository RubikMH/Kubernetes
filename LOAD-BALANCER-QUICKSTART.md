# 🎯 Load Balancer Options - Quick Start

## Three Load Balancers Available!

You now have **three choices** for load balancing your Kubernetes API servers:

1. **HAProxy** - Industry standard, proven
2. **Nginx** - Versatile, familiar
3. **Traefik** - Modern, cloud-native

---

## 🚀 Quick Decision Guide

### 30-Second Choice

**Just want it to work?** → Use **HAProxy** (safest choice)

**Already use Nginx?** → Use **Nginx** (familiar)

**Want modern tools?** → Use **Traefik** (best dashboard)

---

## ⚡ Quick Start Commands

### HAProxy (Recommended for Most)

```bash
# Bash
chmod +x setup-haproxy.sh
sudo ./setup-haproxy.sh

# Ansible
ansible-playbook -i inventory.ini playbook-haproxy.yml

# Monitor
http://lb-ip:9000/stats
```

### Nginx (For Nginx Users)

```bash
# Bash
chmod +x setup-nginx.sh
sudo ./setup-nginx.sh

# Ansible
ansible-playbook -i inventory.ini playbook-nginx.yml

# Monitor
http://lb-ip:8080/nginx-status
```

### Traefik (For Modern Stack)

```bash
# Bash
chmod +x setup-traefik.sh
sudo ./setup-traefik.sh

# Ansible
ansible-playbook -i inventory.ini playbook-traefik.yml

# Dashboard
http://lb-ip:8080/dashboard/
```

---

## 📊 At a Glance

| Feature | HAProxy | Nginx | Traefik |
|---------|---------|-------|---------|
| **Setup Time** | 10 min | 10 min | 12 min |
| **Memory** | ~5 MB | ~5 MB | ~30 MB |
| **Dashboard** | Basic | Basic | Modern |
| **Auto-reload** | No | No | Yes |
| **Best For** | Production | Versatile | Cloud-native |

---

## 🎓 When to Use Each

### Use HAProxy if:
- ✅ Production environment
- ✅ Maximum performance needed
- ✅ Traditional infrastructure
- ✅ Want proven technology
- ✅ Need detailed statistics

### Use Nginx if:
- ✅ Already using Nginx
- ✅ Need web server too
- ✅ Familiar with Nginx config
- ✅ Want versatility
- ✅ Mixed workloads

### Use Traefik if:
- ✅ Cloud-native setup
- ✅ Want modern dashboard
- ✅ Need auto-reload
- ✅ Prefer YAML config
- ✅ Built-in Prometheus metrics

---

## 📁 Files for Each Load Balancer

### HAProxy
**Bash:** `setup-haproxy.sh`  
**Ansible:** `ansible/playbook-haproxy.yml`  
**Template:** `ansible/templates/haproxy.cfg.j2`

### Nginx
**Bash:** `setup-nginx.sh`  
**Ansible:** `ansible/playbook-nginx.yml`  
**Templates:**
- `ansible/templates/nginx-main.conf.j2`
- `ansible/templates/nginx-stream-kubernetes.conf.j2`

### Traefik
**Bash:** `setup-traefik.sh`  
**Ansible:** `ansible/playbook-traefik.yml`  
**Templates:**
- `ansible/templates/traefik-static.yml.j2`
- `ansible/templates/traefik-dynamic-kubernetes.yml.j2`
- `ansible/templates/traefik.service.j2`

---

## 🔧 Configuration Required

### Ansible Inventory

Add one of these groups:

```ini
[haproxy]
haproxy1 ansible_host=192.168.1.5 ansible_user=root

# OR

[nginx]
nginx1 ansible_host=192.168.1.5 ansible_user=root

# OR

[traefik]
traefik1 ansible_host=192.168.1.5 ansible_user=root
```

### group_vars/all.yml

```yaml
# Use same control_plane_endpoint for all
control_plane_endpoint: "192.168.1.5:6443"

# Load balancer specific (optional)
# For HAProxy:
haproxy_apiserver_port: 6443
haproxy_stats_port: 9000

# For Nginx:
nginx_apiserver_port: 6443
nginx_status_port: 8080

# For Traefik:
traefik_apiserver_port: 6443
traefik_dashboard_port: 8080
```

---

## 🎯 Complete Setup Flow

### Option 1: HAProxy (Recommended)

```bash
# 1. Setup load balancer
./setup-haproxy.sh

# 2. Setup Kubernetes
./setup-k8s-master.sh  # Use HAProxy IP
./setup-k8s-worker.sh

# 3. Monitor
curl http://haproxy-ip:9000/stats
```

### Option 2: Nginx

```bash
# 1. Setup load balancer
./setup-nginx.sh

# 2. Setup Kubernetes
./setup-k8s-master.sh  # Use Nginx IP
./setup-k8s-worker.sh

# 3. Monitor
curl http://nginx-ip:8080/nginx-status
```

### Option 3: Traefik

```bash
# 1. Setup load balancer
./setup-traefik.sh

# 2. Setup Kubernetes
./setup-k8s-master.sh  # Use Traefik IP
./setup-k8s-worker.sh

# 3. Monitor (Dashboard)
# Open: http://traefik-ip:8080/dashboard/
```

---

## 📚 Documentation

**Detailed Comparison:**  
→ [LOAD-BALANCER-COMPARISON.md](LOAD-BALANCER-COMPARISON.md)

**HA Setup Guide:**  
→ [HA-SETUP-GUIDE.md](HA-SETUP-GUIDE.md)

**Package Index:**  
→ [PACKAGE-INDEX.md](PACKAGE-INDEX.md)

---

## 🔄 Switching Load Balancers

You can switch between load balancers **without reconfiguring Kubernetes** if you:

1. Use the same IP address
2. Use the same port (6443)
3. Stop old LB before starting new one

Example:
```bash
# Currently using HAProxy
systemctl stop haproxy

# Switch to Nginx (same IP)
./setup-nginx.sh  # Use same IP as HAProxy

# Cluster continues working!
```

---

## ✅ Verification

### All Load Balancers

After setup, verify:

```bash
# 1. Service running
systemctl status <haproxy|nginx|traefik>

# 2. Port listening
netstat -tulpn | grep 6443

# 3. Test (after masters initialized)
curl -k https://lb-ip:6443/healthz
# Should return: ok
```

### HAProxy Specific
```bash
# Check stats
curl http://lb-ip:9000/stats

# All masters should show as "UP" (green)
```

### Nginx Specific
```bash
# Check status
curl http://lb-ip:8080/nginx-status

# View stream logs
tail -f /var/log/nginx/stream-access.log
```

### Traefik Specific
```bash
# Check API
curl http://lb-ip:8080/api/overview

# Check health
curl http://lb-ip:8080/ping
# Should return: OK

# Open dashboard
# http://lb-ip:8080/dashboard/
```

---

## 🆘 Troubleshooting

### Load Balancer Won't Start

**Check logs:**
```bash
# HAProxy
journalctl -u haproxy -n 50

# Nginx
journalctl -u nginx -n 50

# Traefik
journalctl -u traefik -n 50
```

**Common issues:**
- Port 6443 already in use
- Configuration syntax error
- Firewall blocking ports

### Masters Show as Down

**Cause:** Masters not initialized yet (normal)

**Solution:** Initialize masters, then check again

### Connection Refused

**Check:**
1. Load balancer is running
2. Port is correct (6443)
3. Firewall allows port 6443
4. Masters are initialized

---

## 📊 Resource Requirements

| Load Balancer | RAM | CPU | Disk |
|---------------|-----|-----|------|
| **HAProxy** | 1GB | 1 | 20GB |
| **Nginx** | 1GB | 1 | 20GB |
| **Traefik** | 1GB | 1 | 20GB |

All three have similar minimal requirements.

---

## 🎉 Summary

**You have 3 great options:**

1. **HAProxy** - Battle-tested, maximum performance
2. **Nginx** - Versatile, familiar to many
3. **Traefik** - Modern, best dashboard

**Can't decide?** → Use **HAProxy** (safest bet)

**Want to compare?** → See [LOAD-BALANCER-COMPARISON.md](LOAD-BALANCER-COMPARISON.md)

**Ready to setup?** → Pick your load balancer and run the script!

---

**Choose your load balancer and build your HA cluster!** 🚀
