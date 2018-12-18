#!/bin/bash
set -eu

if [ $# -ne 3 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <fedora/centos-UID> <HOW-MANY-NODES>"
  exit -1
fi
NAME_PREFIX=$1
USER=$2
HOW_MANY_NODES=$3
set -x

source ./utils.sh
MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)

ssh $USER@$MASTER_PUBLIC_IP "kubectl delete -f busybox-1.1.yaml -f busybox-1.2.yaml -f busybox-2.1.yaml" || true

read -p "Please now stop the watcher (first), and (then) ODL & then press [Enter] to continue..."

ssh -t $USER@$MASTER_PUBLIC_IP "rm -v karaf*/data/log/karaf.log; rm -fv karaf*/journal/*; rm -fv karaf*/snapshots/*"

scp remote-clean-ovs-veth-ports.sh fedora@$MASTER_PUBLIC_IP:

NODE_NUMBER=1
while [ $NODE_NUMBER -le $HOW_MANY_NODES ]; do
  NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node$NODE_NUMBER)
  ssh -t fedora@$MASTER_PUBLIC_IP "scp remote-clean-ovs-veth-ports.sh $NODE_PRIVATE_IP:"
  ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP './remote-clean-ovs-veth-ports.sh'"
  NODE_NUMBER=$((NODE_NUMBER + 1))
done

echo "Please now start ODL (first, wait until it's up), and (then) the Watcher.. You can then run e.g. ./test.sh again in this reset environment."
