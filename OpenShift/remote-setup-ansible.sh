#!/bin/bash
set -eux

git clone https://github.com/openshift/openshift-ansible || true
cd openshift-ansible
git checkout release-3.11

sudo cp ../hosts /etc/ansible/
ansible-playbook playbooks/prerequisites.yml | tee ../prerequisites.log
ansible-playbook playbooks/deploy_cluster.yml | tee ../deploy_cluster.log

# TODO Automate this...
echo "If the deployment was successful, you should 'sudo reboot now' the master; see https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/6"
echo "Now run 'oc get nodes -o wide' on the master to Verify the Installation!"
