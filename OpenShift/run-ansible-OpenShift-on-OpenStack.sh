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

# https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/4
tee /tmp/ose-dnsmasq.conf > /dev/null << EOF
host-record=$NAME_PREFIX-master.rdocloud,$NAME_PREFIX-master,$MASTER_PRIVATE_IP
host-record=$NAME_PREFIX-node1,$NODE1_PRIVATE_IP
host-record=$NAME_PREFIX-node2,$NODE2_PRIVATE_IP
EOF

tee /tmp/hosts > /dev/null << EOF
[OSEv3:children]
masters
nodes
etcd
lb

[OSEv3:vars]
openshift_release=3.11.0
# some examples use v3.11 with a v prefix and without minor number suffix
openshift_deployment_type=origin
ansible_ssh_user=centos
ansible_become=true
# https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/3
openshift_additional_repos=[{'id': 'centos-okd-ci', 'name': 'centos-okd-ci', 'baseurl' :'http://buildlogs.centos.org/centos/7/paas/x86_64/openshift-origin311/', 'gpgcheck' :'0', 'enabled' :'1'}]
# https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/4
openshift_node_dnsmasq_additional_config_file=/home/centos/ose-dnsmasq.conf

[masters]
$MASTER_PRIVATE_IP

[nodes]
$MASTER_PRIVATE_IP openshift_node_group_name='node-config-master'
$NODE1_PRIVATE_IP openshift_node_group_name='node-config-compute'
$NODE2_PRIVATE_IP openshift_node_group_name='node-config-infra'

[etcd]
$MASTER_PRIVATE_IP

[lb]
# $MASTER_PRIVATE_IP
EOF

scp /tmp/ose-dnsmasq.conf $USER@$ANSIBLE_PUBLIC_IP:
scp /tmp/hosts $USER@$ANSIBLE_PUBLIC_IP:
ssh $USER@$ANSIBLE_PUBLIC_IP "./remote-setup-ansible.sh"
