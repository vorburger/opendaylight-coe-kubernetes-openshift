#!/bin/bash
set -eux

# TODO Cockpit? Later..

# NB We install "ansible pyOpenSSL" on all hosts, not just the ansible jump host, to work around playbooks/prerequisites.yml failure "No module named yaml"
# BUT we need Ansible from EPEL, not CentOS (see https://github.com/vorburger/opendaylight-coe-kubernetes-openshift/issues/2)
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
sudo yum -y --enablerepo=epel install ansible pyOpenSSL

sudo yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
sudo yum -y update
sudo reboot now
