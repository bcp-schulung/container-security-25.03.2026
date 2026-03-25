In this part you need to do the following. Build up and setup a working kubernetes Cluster for each participant. Let them explore and test out that cluster. We recommend that if the participants have been to the introduction to kubernetes seminar that you let them do the setup and instalation on there own for the most part and only interact and work with them in a limited way. 

Below you can find the instalation instructions for a working vanilla kubernetes cluster. These are the base point for everything we are going to do. You need to make sure each participant is up to date in this.

Pre-Requirements:
- 3 Nodes per Participant
- 1 CP - 2 Workers
- Each node should have
    - 2 CPU Cores at LEAST
    - 4 GB of RAM
    - 30 GB Storage

#### Steps to do on each node
```bash
sudo su
cd

apt-get update && apt-get upgrade -y

apt install curl apt-transport-https \
git wget software-properties-common \
lsb-release ca-certificates socat

swapoff -a

modprobe overlay
modprobe br_netfilter

cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
tee /etc/apt/sources.list.d/docker.list

apt-get update && apt-get install containerd.io -y

containerd config default | tee /etc/containerd/config.toml

sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' \
-i /etc/containerd/config.toml

systemctl restart containerd

mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
| gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubeadm=1.33.1-1.1 \
kubelet=1.33.1-1.1 kubectl=1.33.1-1.1

apt-mark hold kubelet kubeadm kubectl

hostname -I
```

These steps will install all required elements that need to be on each node. You "can" just copy and paste them though we recommend that you take the time and do this step by step while explaning everything.

The following steps are now split into "control-plane" and "worker" steps. You need to do both on there respected nodes.

#### Steps for control-plane

```bash
nano /etc/hosts 
# Hier die IP-Adresse der ControlPlane eintragen
# Beispiel:
127.22.16.52 cp

```

The configuration for our Cluster. If needed or wanted add the SDN for your CPS IP and Adress so you can connect via lens/kubectl externaly.

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.33.1
controlPlaneEndpoint: "cp:6443"
networking:
  podSubnet: 192.168.0.0/16
```

```bash
kubeadm init --config=kubeadm-config.yaml --upload-certs --node-name=cp | tee kubeadm-init.out

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.17.2
cilium status --wait


watch kubectl get nodes -o wide

```

#### Steps for workers

```bash
nano /etc/hosts 
# Hier die IP-Adresse der ControlPlane eintragen
# Beispiel:
127.22.16.52 cp


kubeadm join cp:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --certificate-key <key> --node-name=<worker-node-name>
```

When both the CP as well as the workers are running. You can do a simple test that everything is working correctly.

```bash
kubectl create deployment web --image=nginx --replicas=10

kubectl expose deployment web --port=80
```

Once you have done that let the participants think about and then list things that might now be "perfect" or good about this deployment.


This section is all about making the participant aware of how a cluster and applications scale. What benefits are there for scaling and which downsides might arise from a cluster that scales to much or to little. Below is a example that can be used for this.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1   # initial pod count
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:   # required for HPA to know resource requests
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50   # target: 50% CPU usage
```

To test scaling now you can do the following:

```bash
kubectl get deployments
kubectl get hpa
kubectl run -i --tty load-generator --image=busybox -- /bin/sh
# inside container
while true; do wget -q -O- http://nginx-deployment; done
```

One very important part of scaling is making sure that the pods are distributed in a specific way. The next example shows how we could make sure that the application has at least a pod on each node, and then scales based on just traffic.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2   # start with at least 2 pods (for spreading)
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - nginx
              topologyKey: "kubernetes.io/hostname"  
              # ensures pods are scheduled on different nodes
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2    # at least 2 pods, one per node if possible
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50   # scale when average CPU > 50%
```

Another scenario that we sometimes face is making sure that the application perferes a certain node because of location or other critiria. The below example showcases this.

```bash
# Run this once on your cluster (replace node-name with your actual node):
kubectl label nodes node-name preferred-node=true

```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2   # will scale up with HPA
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100   # higher weight = stronger preference
              preference:
                matchExpressions:
                  - key: preferred-node
                    operator: In
                    values:
                      - "true"
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
```

How it behaves:
- Kubernetes will prefer scheduling most pods on the node labeled preferred-node=true.
- If that node runs out of resources, remaining pods will spill over to other nodes.
- The HPA still manages scaling (2 → 10 pods) based on CPU utilization.
