#!/bin/sh
set -ex

# TODO Better security via --remote-ip <ip-address> with CIDR notation (default for IPv4 rule: 0.0.0.0/0) for internal network, only.

# Kubernetes
##############
openstack security group create k8s-master
openstack security group rule create k8s-master --protocol TCP --dst-port 6443:6443
openstack security group rule create k8s-master --protocol TCP --dst-port 2379:2379
openstack security group rule create k8s-master --protocol TCP --dst-port 2380:2380
openstack security group rule create k8s-master --protocol TCP --dst-port 10250:10250
openstack security group rule create k8s-master --protocol TCP --dst-port 10251:10251
openstack security group rule create k8s-master --protocol TCP --dst-port 10252:10252

# Port 9090 for https://cockpit-project.org (HTTPS)
openstack security group rule create k8s-master --protocol TCP --dst-port 9090:9090

# Ports 6640 for OVSDB  &  6653 for OpenFlow  & 4789 for VXLAN (??)
openstack security group rule create k8s-master --protocol TCP --dst-port 6640:6640 --remote-ip 192.168.0.0/24
openstack security group rule create k8s-master --protocol TCP --dst-port 6653:6653 --remote-ip 192.168.0.0/24
openstack security group rule create k8s-master --protocol TCP --dst-port 4789:4789 --remote-ip 192.168.0.0/24

openstack security group create k8s-node
openstack security group rule create k8s-node --protocol TCP --dst-port 10250:10250
openstack security group rule create k8s-node --protocol TCP --dst-port 6640:6640 --remote-ip 192.168.0.0/24
openstack security group rule create k8s-node --protocol TCP --dst-port 6653:6653 --remote-ip 192.168.0.0/24
openstack security group rule create k8s-node --protocol TCP --dst-port 4789:4789 --remote-ip 192.168.0.0/24


# TODO Floating IP
# openstack floating ip create fbf9bcc6-cbaa-4c24-8d56-8010915a6494
# but how to find the Floating Network?
