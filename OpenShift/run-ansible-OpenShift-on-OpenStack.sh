#!/bin/bash
set -eu

NAME_PREFIX=openshift
USER=centos

set -x
source ../utils.sh

ANSIBLE_PUBLIC_IP=$(get_public_IP $NAME_PREFIX-ansible)
MASTER_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-master)
NODE1_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node1)
NODE2_PRIVATE_IP=$(get_private_IP $NAME_PREFIX-node2)

tee /tmp/hosts > /dev/null << EOF
[OSEv3:children]
masters
nodes
etcd
lb

[OSEv3:vars]
openshift_deployment_type=origin
ansible_ssh_user=fedora
ansible_become=true

[masters]
$MASTER_PRIVATE_IP

[nodes]
$NODE1_PRIVATE_IP
$NODE2_PRIVATE_IP

[etcd]
$MASTER_PRIVATE_IP

[lb]
# $MASTER_PRIVATE_IP
EOF

scp /tmp/hosts $USER@$ANSIBLE_PUBLIC_IP:
ssh $USER@$ANSIBLE_PUBLIC_IP "./remote-setup-ansible.sh"
