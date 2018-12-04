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
ssh fedora@$MASTER_PUBLIC_IP "kubectl delete -f busybox-1.1.yaml -f busybox-1.2.yaml -f busybox-2.1.yaml" || true
ssh fedora@$MASTER_PUBLIC_IP "kubectl apply -f busybox-1.1.yaml -f busybox-1.2.yaml -f busybox-2.1.yaml"
# TODO await Pod STATUS Running instead of sleep
sleep 5
ssh fedora@$MASTER_PUBLIC_IP "kubectl get pods -o wide"

busybox12_IP=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubectl get pod busybox-1.2 --template={{.status.podIP}}")
ssh fedora@$MASTER_PUBLIC_IP "kubectl exec -it busybox-1.1 -- ping -c 1 -w 1 $busybox12_IP"

busybox21_IP=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubectl get pod busybox-2.1 --template={{.status.podIP}}")
ssh fedora@$MASTER_PUBLIC_IP "kubectl exec -it busybox-1.1 -- ping -c 1 -w 1 $busybox21_IP"

# TODO deploy a web server and get hello world welcome page via HTTP and using service DNS name instead of IP
