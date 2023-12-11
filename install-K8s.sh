## Execute using 
## curl -s https://raw.githubusercontent.com/learnbyseven/KUBERNETES-TRAINING/master/install-K8s.sh | bash 

#!/bin/bash
echo "Kubernetes vanilla installation begins using KubeADM"
apt-get clean
rm /var/lib/dpkg/lock    
rm /var/cache/apt/archives/lock
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sleep 1
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
sleep 2
apt-get update -y 
sleep 1
sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
sleep 1
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sleep 1 
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
sleep 1 
sudo apt update
sudo apt install git wget curl
sleep 1 
VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest|grep tag_name | cut -d '"' -f 4|sed 's/v//g')
wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz
tar xvf cri-dockerd-${VER}.amd64.tgz
sudo mv cri-dockerd/cri-dockerd /usr/local/bin/
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sleep 1
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sleep 1 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sleep 1 
apt-get update
##Workaround to disable swap on Linux host 
#sed -i -e '2s/^/#/' /etc/fstab
echo "KUBERNETES DEFAULT PACKAGE INSTALLATION BEGINS"
apt-get install -y kubelet kubeadm kubectl
swapoff -a
kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-bind-port=6443 > /kub.txt
mkdir -p $HOME/.kube && cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/custom-resources.yaml

sleep 1
echo "COMPLETED"
#### FINISH 

## Manually add nodes to the server 
## cat /kub.txt
## Execute the /kub.txt on ubuntu system to make it as a member of kubernetes cluster
## Check cluster status 
## kubectl get nodes 
