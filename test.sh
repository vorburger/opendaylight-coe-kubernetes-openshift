#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <NAME_PREFIX>"
  exit -1
fi
NAME_PREFIX=$1
set -x

source ./utils.sh
MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)

scp pods/* fedora@$MASTER_PUBLIC_IP:
ssh fedora@$MASTER_PUBLIC_IP "kubectl delete -f busybox1.yaml -f busybox2.yaml" || true
ssh fedora@$MASTER_PUBLIC_IP "kubectl apply -f busybox1.yaml -f busybox2.yaml"
# TODO await Pod STATUS Running instead of sleep
sleep 5
ssh fedora@$MASTER_PUBLIC_IP "kubectl get pods -o wide"

busybox2_IP=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubectl get pod busybox2 --template={{.status.podIP}}")
ssh fedora@$MASTER_PUBLIC_IP "kubectl exec -it busybox1 -- ping -c 1 -w 1 $busybox2_IP"

# TODO create busybox3 on node2 and ping accross

# TODO deploy a web server and get hello world welcome page via HTTP and using service DNS name instead of IP
