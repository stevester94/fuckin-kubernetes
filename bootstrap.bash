set -eou pipefail

master_hostname=192.168.1.42

sudo yum install -y tmux vim

sudo yum remove -y podman containerd

### BEGIN
# https://docs.docker.com/engine/install/fedora/
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

sudo dnf install -y \
        docker-ce-3:20.10.3-3.fc31 \
        docker-ce-cli-1:20.10.3-3.fc31 \
        containerd.io-1.4.3-3.1.fc31

sudo dnf install -y iproute-tc


# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
### END

### BEGIN
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
### END


### BEGIN
# From https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
### END


### BEGIN
# From https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
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


# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable firewall and swap
sudo systemctl disable --now firewalld
sudo swapoff -a

sudo yum install -y kubelet kubernetes-cni kubeadm kubectl --disableexcludes=kubernetes


sudo systemctl enable --now kubelet
### END

if [[ $1 == "master" ]]; then
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
else
    echo "Get join command from master"
fi
