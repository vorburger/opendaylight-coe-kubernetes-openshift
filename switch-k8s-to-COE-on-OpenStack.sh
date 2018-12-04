#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <COE_DIR>"
  exit -1
fi
NAME_PREFIX=$1
COE_DIR=$2
set -x

source ./utils.sh
MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)
MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)
NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node)

ssh fedora@$MASTER_PUBLIC_IP "sudo dnf install -y openvswitch"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable --now openvswitch"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf install -y openvswitch'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable --now openvswitch'"

# Remove Flannel which was installed in setup-k8s-with-Flannel-on-OpenStack.sh
# kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml || true
## ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo reboot now'" || true
## ssh fedora@$MASTER_PUBLIC_IP "sudo reboot now" || true
# sleep 45

# Reset K8s
ssh -t fedora@$MASTER_PUBLIC_IP "sudo kubeadm reset -f"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo kubeadm reset -f'"


# TODO Replace these "raw" odlCNIPlugin & Watcher binaries and ODL distribution with their respective containerized versions ...

# build-COE.sh $COE_DIR
scp $COE_DIR/watcher/watcher fedora@$MASTER_PUBLIC_IP:
scp $COE_DIR/odlCNIPlugin/odlovs-cni/odlovs-cni fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "scp odlovs-cni $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "sudo mv odlovs-cni /opt/cni/bin"

# TODO replace manager & controller by $MASTER_PRIVATE_IP
scp etc/* fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "sudo mkdir -p /etc/cni/net.d/"
# Remove 10-flannel.conflist or similar which may be left over from previous SDN
ssh -t fedora@$MASTER_PUBLIC_IP "sudo rm -v /etc/cni/net.d/*" || true
ssh -t fedora@$MASTER_PUBLIC_IP "sudo cp master.odlovs-cni.conf /etc/cni/net.d/"

ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mv odlovs-cni /opt/cni/bin'"
ssh -t fedora@$MASTER_PUBLIC_IP "scp worker1.odlovs-cni.conf $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mkdir -p /etc/cni/net.d/'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo cp worker1.odlovs-cni.conf /etc/cni/net.d/'"

# TODO intro ODL_DIR (or not; it will be pulled from a container registry ASAP anyway...)
# scp /home/vorburger/dev/ODL/git/netvirt/karaf/target/karaf-0.8.0-SNAPSHOT.tar.gz fedora@$MASTER_PUBLIC_IP:
# ssh -t fedora@$MASTER_PUBLIC_IP "tar xvzf karaf*.tar.gz"

# Set up K8s again, but w.o. using --pod-network-cidr as that's now in the *-cni.conf
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm init"
ssh fedora@$MASTER_PUBLIC_IP "mkdir -p ~/.kube; sudo cp /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"
# TODO fix "remote version is much newer: v1.13.0; falling back to: stable-1.12" problem..
JOIN_CMD=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubeadm token create --print-join-command")
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo $JOIN_CMD"

ssh fedora@$MASTER_PUBLIC_IP "sudo ovs-vsctl show"
ssh fedora@$MASTER_PUBLIC_IP "kubectl get nodes"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl describe nodes"

echo "Please run the following x3 processes in separate Terminal windows now..."
# We don't integrate Java installation above, because this is very temporary; it will be in the container instead of master ASAP
echo "sudo dnf install java-1.8.0-openjdk-headless"
echo "karaf-0.8.0-SNAPSHOT/bin/karaf"
echo "opendaylight-karaf>feature:install odl-netvirt-coe"
echo "./watcher odl"
