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
