#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <NAME_PREFIX>"
  exit -1
fi
NAME_PREFIX=$1
set -x

# TODO avoid copy/paste between this & setup-k8s-with-Flannel-on-OpenStack.sh, share.. how? "source ./utils.sh" ?

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

scp pods/* fedora@$MASTER_PUBLIC_IP:
# TODO remove all busyboxes, to make this reproducible
ssh fedora@$MASTER_PUBLIC_IP "kubectl apply -f busybox1.yaml -f busybox2.yaml"
# TODO do we need to "sleep 5" ?
ssh fedora@$MASTER_PUBLIC_IP "kubectl get pods -o wide"

busybox2_IP=$(ssh -t fedora@38.145.32.175 "kubectl get pod busybox2 --template={{.status.podIP}}")
ssh fedora@$MASTER_PUBLIC_IP "kubectl exec -it busybox1 -- ping -c 1 -w 1 $busybox2_IP"

# TODO create busybox3 on node2 and ping accross

# TODO deploy a web server and get hello world welcome page via HTTP and using service DNS name instead of IP
