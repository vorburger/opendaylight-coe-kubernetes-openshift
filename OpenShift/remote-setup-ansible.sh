#!/bin/bash
set -eux

git clone https://github.com/openshift/openshift-ansible || true
cd openshift-ansible
git checkout release-3.11

sudo cp ../hosts /etc/ansible/
ansible-playbook playbooks/prerequisites.yml | tee ../prerequisites.log
ansible-playbook playbooks/deploy_cluster.yml | tee ../deploy_cluster.log
