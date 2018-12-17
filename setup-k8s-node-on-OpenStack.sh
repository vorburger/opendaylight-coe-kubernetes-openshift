#!/bin/bash
set -eu

if [ $# -ne 2 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <NODE-NUMBER>"
  exit -1
fi

source ./utils.sh
NAME_PREFIX=$1
NODE_NUMBER=$2
HOSTNAME=$NAME_PREFIX-node$NODE_NUMBER
set -x

MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)

openstack server create --flavor m1.small --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $HOSTNAME
openstack server add security group $NAME_PREFIX-node$NODE_NUMBER k8s-node
NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node$NODE_NUMBER)
# Sleep is still needed, even though get_private_IP() checks for ACTIVE and IP :()
sleep 10
ssh fedora@$MASTER_PUBLIC_IP "ssh -o StrictHostKeyChecking=no $NODE_PRIVATE_IP 'sudo dnf -y update'"
# TODO Install cockpit-kubernetes when figured out how to avoid https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/1
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf -y install cockpit cockpit-bridge cockpit-dashboard cockpit-docker cockpit-networkmanager cockpit-selinux cockpit-system'"
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable --now cockpit.socket'"
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo reboot now'" || true
sleep 10

# TODO Avoid the copy/paste from above here by externalizing into a separate script...
scp kubernetes.repo fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "scp kubernetes.repo $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable kubelet ; sudo systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo kubeadm config images pull'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'"

JOIN_CMD=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubeadm token create --print-join-command")
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo $JOIN_CMD"

# Label the node so that we can constrain scheduling pods onto specific ones, which is useful for tests
ssh -t fedora@$MASTER_PUBLIC_IP "kubectl label nodes $HOSTNAME.rdocloud node=$NODE_NUMBER"
