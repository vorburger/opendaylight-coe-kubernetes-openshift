#!/bin/bash
set -eux

# TODO Cockpit? Later..
# NB We install "ansible pyOpenSSL" on all hosts, not just the ansible jump host, to work around playbooks/prerequisites.yml failure "No module named yaml"
sudo dnf install -y ansible pyOpenSSL wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
sudo dnf -y update
sudo reboot now
