# Kubernetes Cluster Setup Scripts

Two bash scripts to automate Kubernetes cluster setup on Debian 12.

## Files

1. **setup-k8s-master.sh** - Sets up the control plane/master node
2. **setup-k8s-worker.sh** - Prepares worker nodes to join the cluster

## Prerequisites

- Debian 12 (Bookworm) installed on all nodes
- Minimum 2GB RAM, 2 CPUs per node
- Root or sudo access
- Network connectivity between all nodes

## Usage

### Step 1: Setup Master Node

On your master/control-plane node:

```bash
# Make the script executable
chmod +x setup-k8s-master.sh

# Run the script
sudo ./setup-k8s-master.sh
```

**What the master script does:**
- Updates system packages
- Sets hostname to "control-plane"
- Disables swap (required by Kubernetes)
- Loads required kernel modules (overlay, br_netfilter)
- Configures sysctl parameters for networking
- Installs containerd container runtime
- Configures containerd with SystemdCgroup
- Installs Kubernetes components (kubeadm, kubelet, kubectl)
- Initializes the Kubernetes cluster
- Configures kubectl for the current user
- Installs Flannel CNI for pod networking
- Generates and displays the worker join command

**Important:** At the end, the script will display a join command. **Save this command!** You'll need it for worker nodes.

Example output:
```bash
kubeadm join 192.168.1.10:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

The join command is also saved to: `/root/k8s-join-command.txt`

### Step 2: Setup Worker Nodes

On each worker node:

```bash
# Make the script executable
chmod +x setup-k8s-worker.sh

# Run the script
sudo ./setup-k8s-worker.sh
```

**What the worker script does:**
- Updates system packages
- Prompts for hostname (e.g., worker1, worker2)
- Disables swap
- Loads required kernel modules
- Configures sysctl parameters
- Installs containerd container runtime
- Configures containerd with SystemdCgroup
- Installs Kubernetes components (kubeadm, kubelet, kubectl)
- Prepares the node to join the cluster
- Optionally allows you to join immediately

**During the script:**
- You'll be prompted to enter a hostname for the worker
- At the end, you can optionally paste the join command to join immediately

**If you skip joining during the script:**

You can join manually later:

```bash
sudo kubeadm join <master-ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

### Step 3: Verify Cluster

On the master node:

```bash
# Check all nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# View detailed node information
kubectl get nodes -o wide
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   10m   v1.28.15
worker1         Ready    <none>          5m    v1.28.15
worker2         Ready    <none>          5m    v1.28.15
```

## Timeline

- **Master setup**: ~5-10 minutes
- **Worker setup**: ~3-5 minutes per node
- **Total for 1 master + 2 workers**: ~15-20 minutes

## Troubleshooting

### Token Expired

Tokens expire after 24 hours. Generate a new one:

```bash
# On master node
kubeadm token create --print-join-command
```

### Worker Node Won't Join

Check connectivity and logs:

```bash
# Test connection to master
ping <master-ip>
telnet <master-ip> 6443

# Check kubelet logs
sudo journalctl -u kubelet -f

# Check containerd
sudo systemctl status containerd
```

### Node Shows "NotReady"

Usually means CNI plugin hasn't started:

```bash
# On master, check CNI pods
kubectl get pods -n kube-system | grep flannel

# Restart a node's kubelet
sudo systemctl restart kubelet
```

### Reset a Node

If you need to start over:

```bash
# On the node you want to reset
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/kubernetes
sudo iptables -F && sudo iptables -t nat -F
```

Then run the setup script again.

## Important Commands

### Master Node Commands

```bash
# Get join command
kubeadm token create --print-join-command

# List all tokens
kubeadm token list

# View cluster info
kubectl cluster-info

# Check all pods
kubectl get pods -A

# View nodes
kubectl get nodes -o wide
```

### Worker Node Commands

```bash
# Check kubelet status
sudo systemctl status kubelet

# View kubelet logs
sudo journalctl -u kubelet -f

# Check container runtime
sudo systemctl status containerd
```

## Network Ports Required

### Master Node
- **6443**: Kubernetes API server
- **2379-2380**: etcd server client API
- **10250**: Kubelet API
- **10259**: kube-scheduler
- **10257**: kube-controller-manager

### Worker Nodes
- **10250**: Kubelet API
- **30000-32767**: NodePort Services

### All Nodes
- **Pod network**: 10.244.0.0/16 (Flannel default)

## What Gets Installed

### Both Master and Worker
- containerd (container runtime)
- kubelet (node agent)
- kubeadm (cluster management tool)
- kubectl (command-line tool)
- Flannel CNI (network plugin)

### Master Only
- kube-apiserver (API server)
- etcd (key-value store)
- kube-scheduler (pod scheduler)
- kube-controller-manager (controller manager)
- kube-proxy (network proxy)

## Configuration Files

### Important directories:
- `/etc/kubernetes/` - Kubernetes configuration
- `/var/lib/kubelet/` - Kubelet data
- `/etc/containerd/` - containerd configuration
- `/etc/cni/net.d/` - CNI network configuration
- `~/.kube/config` - kubectl configuration

## Security Notes

1. **Keep join tokens secure** - They provide access to your cluster
2. **Tokens expire** - Default is 24 hours (for security)
3. **Update regularly** - Keep Kubernetes and containerd updated
4. **Use firewall rules** - Restrict access to required ports only
5. **Backup etcd** - Regular backups of the etcd database on master

## Next Steps After Setup

1. **Deploy your first application**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl expose deployment nginx --port=80 --type=NodePort
   kubectl get svc nginx
   ```

2. **Install metrics server** (for resource monitoring)
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

3. **Set up ingress controller** (for HTTP/HTTPS routing)
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
   ```

4. **Configure storage** (persistent volumes for stateful apps)

5. **Set up monitoring** (Prometheus, Grafana)

6. **Configure backups** (etcd snapshots)

## Common Issues and Solutions

### Issue: "The connection to the server X.X.X.X:6443 was refused"

**Solution:** API server isn't running or certificates are invalid

```bash
# Check API server
sudo crictl ps | grep kube-apiserver

# Check kubelet logs
sudo journalctl -u kubelet -f

# Restart kubelet
sudo systemctl restart kubelet
```

### Issue: Pods stuck in "ContainerCreating"

**Solution:** CNI network plugin issue

```bash
# Check Flannel pods
kubectl get pods -n kube-system | grep flannel

# Restart Flannel
kubectl delete pods -n kube-system -l app=flannel
```

### Issue: "error execution phase preflight: couldn't validate the identity of the API Server"

**Solution:** Certificate hash is incorrect or master is unreachable

```bash
# On master, get correct hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
   openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

## Support and Documentation

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **kubeadm Documentation**: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- **Flannel Documentation**: https://github.com/flannel-io/flannel
- **containerd Documentation**: https://containerd.io/docs/

## Script Features

Both scripts include:
- ✅ Detailed comments explaining each step
- ✅ Color-coded output for easy reading
- ✅ Error checking and validation
- ✅ Progress indicators
- ✅ Automatic cleanup on failure
- ✅ Status verification after each step
- ✅ Helpful error messages
- ✅ Post-installation instructions

## License

These scripts are provided as-is for educational and production use.