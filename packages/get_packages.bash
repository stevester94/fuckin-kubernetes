wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/33/Everything/x86_64/os/Packages/l/libnetfilter_cttimeout-devel-1.0.0-16.fc33.x86_64.rpm
wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/33/Everything/x86_64/os/Packages/l/libnetfilter_queue-1.0.2-16.fc33.x86_64.rpm
wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/33/Everything/x86_64/os/Packages/c/conntrack-tools-1.4.5-6.fc33.x86_64.rpm
wget https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/33/Everything/x86_64/os/Packages/l/libnetfilter_cthelper-1.0.0-18.fc33.x86_64.rpm

# This is actually a little old
CNI_VERSION="v0.8.2"
# mkdir -p /opt/cni/bin
#curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-Linux-amd64-${CNI_VERSION}.tgz" |  tar -C /opt/cni/bin -xz
wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-Linux-amd64-${CNI_VERSION}.tgz"

DOWNLOAD_DIR=/usr/local/bin
# mkdir -p $DOWNLOAD_DIR

CRICTL_VERSION="v1.17.0"
#curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-Linux-amd64.tar.gz" |  tar -C $DOWNLOAD_DIR -xz
wget "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-Linux-amd64.tar.gz"

#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.20.5"
#cd $DOWNLOAD_DIR
wget https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
#chmod +x {kubeadm,kubelet,kubectl}

RELEASE_VERSION="v0.4.0"
#curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" |  tee /etc/systemd/system/kubelet.service
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" > kubelet.service

#mkdir -p /etc/systemd/system/kubelet.service.d

#curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" |  tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" > 10-kubeadm.conf
