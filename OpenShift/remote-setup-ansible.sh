#!/bin/bash
set -eux

git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
git checkout release-3.11

sudo cp ../hosts /etc/ansible/
cd openshift-ansible
ansible-playbook playbooks/prerequisites.yml
