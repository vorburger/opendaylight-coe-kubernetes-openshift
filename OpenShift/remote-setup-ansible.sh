#!/bin/bash
set -ex

sudo dnf install -y ansible pyOpenSSL

git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
git checkout release-3.11