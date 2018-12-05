#!/bin/bash
set -e

NAME_PREFIX=openshift

set -x
source ./utils.sh

openstack server create --flavor m1.small --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-ansible
openstack server add floating ip $NAME_PREFIX-ansible 38.145.33.97

openstack server create --flavor m1.xlarge --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-master
openstack server create --flavor m1.large --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-node1
openstack server create --flavor m1.large --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop $NAME_PREFIX-node2

openstack server add security group $NAME_PREFIX-master openshift-master
openstack server add security group $NAME_PREFIX-node1 openshift-node
openstack server add security group $NAME_PREFIX-node2 openshift-node

ANSIBLE_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-ansible)
scp {remote-setup-common.sh,remote-setup-ansible.sh} fedora@$ANSIBLE_PUBLIC_IP:
ssh fedora@$ANSIBLE_PUBLIC_IP "./remote-setup-common.sh"
sleep 10

MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)
ssh fedora@$ANSIBLE_PUBLIC_IP "scp remote-setup-common.sh fedora@$MASTER_PRIVATE_IP: ; ssh fedora@$MASTER_PRIVATE_IP ./remote-setup-common.sh"
NODE1_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node1)
ssh fedora@$ANSIBLE_PUBLIC_IP "scp remote-setup-common.sh fedora@$NODE1_PRIVATE_IP: ; ssh fedora@$NODE1_PRIVATE_IP ./remote-setup-common.sh"
NODE2_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node2)
ssh fedora@$ANSIBLE_PUBLIC_IP "scp remote-setup-common.sh fedora@$NODE2_PRIVATE_IP: ; ssh fedora@$NODE2_PRIVATE_IP ./remote-setup-common.sh"

scp hosts fedora@$ANSIBLE_PUBLIC_IP:
ssh fedora@$ANSIBLE_PUBLIC_IP "sudo cp hosts /etc/ansible/"
ssh fedora@$ANSIBLE_PUBLIC_IP "./remote-setup-ansible.sh"
