#!/bin/bash
set -eu

if [ $# -ne 3 ]; then
  echo "USAGE: $0 <NAME_PREFIX> <COE_DIR> <HOW-MANY-NODES>"
  exit -1
fi
NAME_PREFIX=$1
COE_DIR=$2
HOW_MANY_NODES=$3
set -x

source ./utils.sh
MASTER_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-master)
MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)

ssh fedora@$MASTER_PUBLIC_IP "sudo dnf install -y openvswitch"
ssh fedora@$MASTER_PUBLIC_IP "sudo systemctl enable --now openvswitch"

# Remove Flannel which was installed in setup-k8s-with-Flannel-on-OpenStack.sh
# kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml || true
## ssh fedora@$MASTER_PUBLIC_IP "ssh $NODE_PRIVATE_IP 'sudo reboot now'" || true
## ssh fedora@$MASTER_PUBLIC_IP "sudo reboot now" || true
# sleep 45

# Reset K8s
ssh -t fedora@$MASTER_PUBLIC_IP "sudo kubeadm reset -f"


# TODO Replace these "raw" odlCNIPlugin & Watcher binaries and ODL distribution with their respective containerized versions ...

# build-COE.sh $COE_DIR
scp $COE_DIR/watcher/watcher fedora@$MASTER_PUBLIC_IP:
scp $COE_DIR/odlCNIPlugin/odlovs-cni/odlovs-cni fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "sudo mv odlovs-cni /opt/cni/bin"

tee /tmp/odlovs-cni-master.conf > /dev/null << EOF
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
        "subnet":"10.11.0.0/24",
        "routes":[{
            "dst":"0.0.0.0/0"
        }],
        "gateway":"10.11.0.1"
    }
}
EOF
ssh -t fedora@$MASTER_PUBLIC_IP "sudo mkdir -p /etc/cni/net.d/"
# Remove 10-flannel.conflist or similar which may be left over from previous SDN
ssh -t fedora@$MASTER_PUBLIC_IP "sudo rm -v /etc/cni/net.d/*" || true
scp /tmp/odlovs-cni-master.conf fedora@$MASTER_PUBLIC_IP:
ssh -t fedora@$MASTER_PUBLIC_IP "sudo cp odlovs-cni-master.conf /etc/cni/net.d/"

# TODO intro ODL_DIR (or not; it will be pulled from a container registry ASAP anyway...)
# scp /home/vorburger/dev/ODL/git/netvirt/karaf/target/karaf-0.8.0-SNAPSHOT.tar.gz fedora@$MASTER_PUBLIC_IP:
# ssh -t fedora@$MASTER_PUBLIC_IP "tar xvzf karaf*.tar.gz"

# Set up K8s again, but w.o. using --pod-network-cidr as that's now in the *-cni.conf
ssh fedora@$MASTER_PUBLIC_IP "sudo kubeadm init"
ssh fedora@$MASTER_PUBLIC_IP "mkdir -p ~/.kube; sudo cp /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"

NODE_NUMBER=1
while [ $NODE_NUMBER -le $HOW_MANY_NODES ]; do
  ./switch-k8s-node-to-COE-on-OpenStack.sh $NAME_PREFIX $NODE_NUMBER
  NODE_NUMBER=$((NODE_NUMBER + 1))
done

echo "Now please run the following x3 processes in separate Terminal windows now..."
# We don't integrate Java installation above, because this is very temporary; it will be in the container instead of master ASAP
echo "sudo dnf install java-1.8.0-openjdk-headless"
echo "karaf-0.8.0-SNAPSHOT/bin/karaf"
echo "opendaylight-karaf>feature:install odl-netvirt-coe"
echo "./watcher odl"

# ssh fedora@$MASTER_PUBLIC_IP "sudo ovs-vsctl show"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl get nodes"
# ssh fedora@$MASTER_PUBLIC_IP "kubectl describe nodes"
