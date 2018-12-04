#!/bin/bash
set -e

# TODO avoid copy/paste between this & setup-k8s-with-Flannel-on-OpenStack.sh, share.. how? "source ./utils.sh" ?

if [ $# -ne 2 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <COE_DIR>"
  exit -1
fi
NAME_PREFIX=$1
COE_DIR=$2
set -x

get_private_IP() {
    local NAME=$1
    local IP=$(openstack server list --name $NAME -c Networks --format value | sed 's/private=\([0-9.]\+\).*/\1/')
    # TODO check that $IP is not empty, wait longer if it is, eventually abandon
    echo $IP
    # ^^ NB Bash foo - must "echo" not "return" for non-numeric reply.
}
get_public_IP() {
    local NAME=$1
    local IP=$(openstack server list --name $NAME -c Networks --format value | sed 's/private=\([0-9.]\+\), \([0-9.]\+\)/\2/')
    # TODO check that $IP is not empty, wait longer if it is, eventually abandon
    echo $IP
}
MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)
NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node)

ssh fedora@$MASTER_PUBLIC_IP "sudo dnf install -y openvswitch"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf install -y openvswitch'"

# Remove Flannel which was installed in setup-k8s-with-Flannel-on-OpenStack.sh
kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo reboot now'" || true
ssh fedora@$MASTER_PUBLIC_IP "sudo reboot now" || true
sleep 45


# TODO Replace these "raw" odlCNIPlugin & Watcher binaries and ODL distribution with their respective containerized versions ...

# build-COE.sh $COE_DIR
scp $COE_DIR/odlCNIPlugin/odlovs-cni/odlovs-cni fedora@$MASTER_PUBLIC_IP:
scp $COE_DIR/odlCNIPlugin/watcher/watcher fedora@$MASTER_PUBLIC_IP:

scp etc/* fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "sudo mkdir -p /etc/cni/net.d/"
# Remove 10-flannel.conflist or similar which may be left over from previous SDN
ssh -t fedora@$MASTER_PUBLIC_IP "sudo rm -v /etc/cni/net.d/*"
ssh -t fedora@$MASTER_PUBLIC_IP "sudo cp master.odlovs-cni.conf /etc/cni/net.d/"

ssh -t fedora@$MASTER_PUBLIC_IP "scp worker1.odlovs-cni.conf $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mkdir -p /etc/cni/net.d/'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo cp worker1.odlovs-cni.conf /etc/cni/net.d/'"

# TODO intro ODL_DIR (or not; it will be pulled from a container registry ASAP anyway...)
scp /home/vorburger/dev/ODL/git/netvirt/karaf/target/karaf-0.8.0-SNAPSHOT.tar.gz fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "tar xvzf karaf*.tar.gz"

echo "Please run the following x3 processes in separate Terminal windows now..."
# We don't integrate Java installation above, because this is very temporary; it will be in the container instead of master ASAP
echo "sudo dnf install java-1.8.0-openjdk-headless"
echo "karaf-0.8.0-SNAPSHOT/bin/karaf"
echo "opendaylight-karaf>feature:install odl-netvirt-coe"
# TODO CNI_COMMAND ??
echo "./odlovs-cni"
echo "./watcher odl"
