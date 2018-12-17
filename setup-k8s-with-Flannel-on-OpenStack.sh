#!/bin/bash
set -eu

if [ $# -ne 3 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <MASTER_PUBLIC_IP> <HOW-MANY-NODES>"
  exit -1
fi
NAME_PREFIX=$1
MASTER_PUBLIC_IP=$2
HOW_MANY_NODES=$3
set -x

# TODO Avoid all 'sleep' by using sth like https://github.com/Jaanki/openstack/blob/master/scripts/create_vm.sh#L26
# TODO How to send all ssh commands over a single connection, yet still get echo?

source ./utils.sh

openstack server create --flavor m1.medium --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-master
openstack server add security group $NAME_PREFIX-master k8s-master
openstack server add floating ip $NAME_PREFIX-master $MASTER_PUBLIC_IP
ssh-keygen -R $MASTER_PUBLIC_IP || true
ssh -o StrictHostKeyChecking=no fedora@$MASTER_PUBLIC_IP "sudo dnf -y update"
# TODO Install cockpit-kubernetes when figured out how to avoid https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/1
ssh fedora@$MASTER_PUBLIC_IP "sudo dnf -y install cockpit cockpit-bridge cockpit-dashboard cockpit-docker cockpit-networkmanager cockpit-selinux cockpit-system"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable --now cockpit.socket"
ssh fedora@$MASTER_PUBLIC_IP "sudo reboot now" || true
sleep 10

scp kubernetes.repo fedora@$MASTER_PUBLIC_IP:
ssh fedora@$MASTER_PUBLIC_IP "sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo"
ssh fedora@$MASTER_PUBLIC_IP "sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh fedora@$MASTER_PUBLIC_IP "sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker"
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm config images pull"
ssh fedora@$MASTER_PUBLIC_IP "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
ssh fedora@$MASTER_PUBLIC_IP "mkdir -p ~/.kube; sudo cp /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"

NODE_NUMBER=1
while [ $NODE_NUMBER -le $HOW_MANY_NODES ]; do
  ./setup-k8s-node-on-OpenStack.sh $NAME_PREFIX $NODE_NUMBER
  NODE_NUMBER=$((NODE_NUMBER + 1))
done

# Set up Flannel
# ssh -t fedora@$MASTER_PUBLIC_IP "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"
# sleep 60
# ssh fedora@$MASTER_PUBLIC_IP "kubectl get pods --all-namespaces"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl get nodes"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl describe nodes"
