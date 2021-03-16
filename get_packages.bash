set -eou pipefail

master_hostname=192.168.1.42

sudo yum remove -y podman containerd

### BEGIN
# https://docs.docker.com/engine/install/fedora/
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo



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

mkdir -p /tmp/F31_kubernetes_packages

sudo dnf install \
docker-ce-3:20.10.3-3.fc31 \
docker-ce-cli-1:20.10.3-3.fc31 \
containerd.io-1.4.3-3.1.fc31 \
iproute-tc \
kubelet kubernetes-cni kubeadm kubectl --disableexcludes=kubernetes \
--downloadonly --downloaddir=/tmp/F31_kubernetes_packages 
