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

ssh $USER@$ANSIBLE_PUBLIC_IP "scp -o StrictHostKeyChecking=no remote-setup-common.sh $USER@$MASTER_PRIVATE_IP: ; ssh $USER@$MASTER_PRIVATE_IP ./remote-setup-common.sh"
ssh $USER@$ANSIBLE_PUBLIC_IP "scp -o StrictHostKeyChecking=no remote-setup-common.sh $USER@$NODE1_PRIVATE_IP: ; ssh $USER@$NODE1_PRIVATE_IP ./remote-setup-common.sh"
ssh $USER@$ANSIBLE_PUBLIC_IP "scp -o StrictHostKeyChecking=no remote-setup-common.sh $USER@$NODE2_PRIVATE_IP: ; ssh $USER@$NODE2_PRIVATE_IP ./remote-setup-common.sh"

tee /tmp/hosts > /dev/null << EOF
[OSEv3:children]
masters
nodes
etcd
lb

[OSEv3:vars]
openshift_deployment_type=origin
# openshift_release=3.11.0
ansible_ssh_user=centos
ansible_become=true

[masters]
$MASTER_PRIVATE_IP

[nodes]
$MASTER_PRIVATE_IP openshift_node_group_name='node-config-master'
$NODE1_PRIVATE_IP openshift_node_group_name='node-config-compute'
$NODE2_PRIVATE_IP openshift_node_group_name='node-config-compute'

[etcd]
$MASTER_PRIVATE_IP

[lb]
# $MASTER_PRIVATE_IP
EOF

scp /tmp/hosts $USER@$ANSIBLE_PUBLIC_IP:
ssh $USER@$ANSIBLE_PUBLIC_IP "./remote-setup-ansible.sh"
