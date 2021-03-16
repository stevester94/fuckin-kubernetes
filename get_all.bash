set -eou pipefail

master_hostname=192.168.1.42

sudo yum remove -y podman containerd

### BEGIN
# https://docs.docker.com/engine/install/fedora/
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

mkdir -p $HOME/packages
mkdir -p /tmp/packages

sudo dnf install -y \
docker-ce-3:20.10.3-3.fc31 \
docker-ce-cli-1:20.10.3-3.fc31 \
containerd.io-1.4.3-3.1.fc31 \
iproute-tc \
--downloadonly --downloaddir=/tmp/packages

mv /tmp/packages/* $HOME/packages
echo Packages are in $HOME/packages


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


sudo dnf install -y \
kubelet kubernetes-cni kubeadm kubectl --disableexcludes=kubernetes \
--downloadonly --downloaddir=/tmp/packages

mv /tmp/packages/* $HOME/packages


# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable firewall and swap
sudo systemctl disable --now firewalld
sudo swapoff -a

sudo yum install -y kubelet kubernetes-cni kubeadm kubectl --disableexcludes=kubernetes

mkdir -p $HOME/images/

for image in $(kubeadm config images list); do
    sudo docker pull $image
    sudo docker save $image > $HOME/images/$(echo $image.cimage | tr / _)
done

cd $HOME
mkdir Fedora31_kubernetes_images_and_packages
mv images packages Fedora31_kubernetes_images_and_packages
tar cvfz Fedora31_kubernetes_images_and_packages.tar.gz Fedora31_kubernetes_images_and_packages
