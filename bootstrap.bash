master_hostname=192.168.1.46
# Hack to make /usr writable
sudo mount -o remount,rw /dev/sda4 /usr

rpm -i *rpm

sudo systemctl start docker
sudo systemctl enable docker

sudo touch /etc/docker/daemon.json
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

sudo touch /etc/systemd/system/docker.service.d/docker.conf
cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/docker.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker


CNI_VERSION="v0.8.2"
sudo mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-Linux-amd64-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz

DOWNLOAD_DIR=/usr/local/bin
sudo mkdir -p $DOWNLOAD_DIR

CRICTL_VERSION="v1.17.0"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-Linux-amd64.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}

RELEASE_VERSION="v0.4.0"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl enable --now kubelet


cat <<EOF | sudo tee /etc/sysctl.d/K8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

if [[ $1 == "master" ]]; then
    sudo kubeadm init

    # Config kubectl
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Untaint the master (We want to be able to run stuff even on master)
    kubectl taint nodes --all node-role.kubernetes.io/master-

    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    
    # There's a bit of a race condition since the API doesn't even return any pods for a bit.
    # This sleep seems like a lot, but we have to wait for weave to deploy anyways so its not so bad
    echo "Waiting for weave to come up before redeploying coredns"
    sleep 15
    kubectl wait --namespace=kube-system --for=condition=Ready --timeout=-1s --all pods

    # CoreDNS needs to restart and get weavenet IPs
    kubectl --namespace=kube-system rollout restart deployment coredns


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

