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
MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)
NODE_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node$NODE_NUMBER)

ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo dnf install -y openvswitch'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo systemctl enable --now openvswitch'"

ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo kubeadm reset -f'"

ssh -t fedora@$MASTER_PUBLIC_IP "scp /opt/cni/bin/odlovs-cni $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mv odlovs-cni /opt/cni/bin'"

tee /tmp/odlovs-cni-node$NODE_NUMBER.conf > /dev/null << EOF
{
    "cniVersion":"0.3.0",
    "name":"odl-cni",
    "type":"odlovs-cni",
    "mgrPort":6640,
    "mgrActive":true,
    "manager":"$MASTER_PRIVATE_IP",
    "ovsBridge":"br-int",
    "ctlrPort":6653,
    "ctlrActive":true,
    "controller":"$MASTER_PRIVATE_IP",
    "externalIntf":"",
    "externalIp":"",
    "ipam":{
        "type":"host-local",
        "subnet":"10.11.$NODE_NUMBER.0/24",
        "routes":[{
            "dst":"0.0.0.0/0"
        }],
        "gateway":"10.11.$NODE_NUMBER.1"
    }
}
EOF
scp /tmp/odlovs-cni-node$NODE_NUMBER.conf fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "scp odlovs-cni-node$NODE_NUMBER.conf $NODE_PRIVATE_IP:"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo mkdir -p /etc/cni/net.d/'"
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo cp odlovs-cni-node$NODE_NUMBER.conf /etc/cni/net.d/'"

JOIN_CMD=$(ssh -t fedora@$MASTER_PUBLIC_IP "kubeadm token create --print-join-command")
ssh -t fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP sudo $JOIN_CMD"

# Label the node so that we can constrain scheduling pods onto specific ones, which is useful for tests
ssh -t fedora@$MASTER_PUBLIC_IP "kubectl label nodes $HOSTNAME.rdocloud node=$NODE_NUMBER"
