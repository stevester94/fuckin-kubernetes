set -eou pipefail

master_hostname=192.168.1.42

sudo yum install -y tmux vim

sudo yum install -y yum-utils


cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


sudo yum remove -y podman containerd

sudo yum install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd


cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubernetes-cni kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl disable --now firewalld

sudo swapoff -a

sudo systemctl enable --now kubelet

sudo kubeadm init

# Config kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Untaint the master (We want to be able to run stuff even on master)
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"



CONTROL_PLANE_PORT=6443 # This is the default port
TOKEN=$(kubeadm token list | sed 1d | awk '{print $1}')
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
JOIN_COMMAND=$(printf 'kubeadm join --token %s %s:%s --discovery-token-ca-cert-hash sha256:%s' $TOKEN $master_hostname $CONTROL_PLANE_PORT $CERT_HASH)

echo "The command to join is:"
echo $JOIN_COMMAND
echo --
echo "It will be written to $HOME/join_command.bash"
echo $JOIN_COMMAND > $HOME/join_command.bash
