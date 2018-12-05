#!/bin/sh
set -ex

# see https://docs.okd.io/latest/install/prerequisites.html#required-ports
# and https://docs.okd.io/latest/install_config/configuring_openstack.html#configuring-a-security-group-openstack

openstack security group create openshift-master
openstack security group rule create openshift-master --protocol TCP --dst-port 443:443
openstack security group rule create openshift-master --protocol TCP --dst-port 8443:8443
openstack security group rule create openshift-master --protocol TCP --dst-port 4789:4789 --remote-ip 192.168.0.0/24
openstack security group rule create openshift-master --protocol TCP --dst-port 8053:8053 --remote-ip 192.168.0.0/24
openstack security group rule create openshift-master --protocol UDP --dst-port 8053:8053 --remote-ip 192.168.0.0/24

# Port 9090 for https://cockpit-project.org (HTTPS)
openstack security group rule create openshift-master --protocol TCP --dst-port 9090:9090


openstack security group create openshift-node
openstack security group rule create openshift-node --protocol TCP --dst-port 4789:4789 --remote-ip 192.168.0.0/24
openstack security group rule create openshift-node --protocol TCP --dst-port 10250:10250 --remote-ip 192.168.0.0/24
