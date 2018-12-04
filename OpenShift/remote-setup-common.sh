#!/bin/bash
set -ex

# TODO Cockpit? Later..
sudo dnf install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
sudo dnf -y update
sudo reboot now
