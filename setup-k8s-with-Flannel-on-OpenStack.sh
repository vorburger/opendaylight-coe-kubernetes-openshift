#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <MASTER_PUBLIC_IP>"
  exit -1
fi
NAME_PREFIX=$1
MASTER_PUBLIC_IP=$2
set -x

# TODO Avoid all 'sleep' by using sth like https://github.com/Jaanki/openstack/blob/master/scripts/create_vm.sh#L26
# TODO How to send all ssh commands over a single connection, yet still get echo?

get_private_IP() {
    local NAME=$1
    local IP=$(openstack server list --name $NAME -c Networks --format value | sed 's/private=\([0-9.]\+\).*/\1/')
    # TODO check that $IP is not empty, wait longer if it is, eventually abandon
    echo $IP
    # ^^ NB Bash foo - must "echo" not "return" for non-numeric reply.
}

openstack server create --flavor m1.medium --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-master
openstack server add security group $NAME_PREFIX-master k8s-master
openstack server add floating ip $NAME_PREFIX-master $MASTER_PUBLIC_IP
sleep 30
MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)
ssh-keygen -R $MASTER_PUBLIC_IP || true
ssh -o StrictHostKeyChecking=no fedora@$MASTER_PUBLIC_IP "sudo dnf -y update"
ssh fedora@$MASTER_PUBLIC_IP "sudo dnf -y install cockpit cockpit-bridge cockpit-dashboard cockpit-kubernetes cockpit-docker cockpit-networkmanager cockpit-selinux cockpit-system"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable --now cockpit.socket"
ssh fedora@$MASTER_PUBLIC_IP "sudo reboot now" || true

openstack server create --flavor m1.small --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-node
sleep 30
openstack server add security group $NAME_PREFIX-node k8s-node
NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node)
ssh fedora@$MASTER_PUBLIC_IP "ssh -o StrictHostKeyChecking=no $NODE_PRIVATE_IP 'sudo dnf -y update'"
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf -y install cockpit cockpit-bridge cockpit-dashboard cockpit-kubernetes cockpit-docker cockpit-networkmanager cockpit-selinux cockpit-system'"
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable --now cockpit.socket'"
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo reboot now'" || true

scp kubernetes.repo fedora@$MASTER_PUBLIC_IP:
ssh fedora@$MASTER_PUBLIC_IP "sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo"
ssh fedora@$MASTER_PUBLIC_IP "sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh fedora@$MASTER_PUBLIC_IP "sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker"
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm config images pull"
ssh fedora@$MASTER_PUBLIC_IP "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
ssh fedora@$MASTER_PUBLIC_IP "mkdir -p ~/.kube; sudo cp /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"

# TODO Avoid the copy/paste from above here by externalizing into a separate script...
scp kubernetes.repo fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "scp kubernetes.repo $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo kubeadm config images pull'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'"

JOIN_CMD=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubeadm token create --print-join-command")
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo $JOIN_CMD"

# Set up Flannel
ssh -t fedora@$MASTER_PUBLIC_IP "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"
sleep 60
ssh fedora@$MASTER_PUBLIC_IP "kubectl get pods --all-namespaces"
ssh fedora@$MASTER_PUBLIC_IP "kubectl get nodes"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl describe nodes"

# TODO Test that it all really works by running some "hello, world" container... ;-)
