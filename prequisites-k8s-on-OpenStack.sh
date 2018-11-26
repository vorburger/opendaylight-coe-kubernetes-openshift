#!/bin/sh
set -ex

openstack security group create k8s-master
openstack security group rule create k8s-master --protocol TCP --dst-port 6443:6443
openstack security group rule create k8s-master --protocol TCP --dst-port 2379:2379
openstack security group rule create k8s-master --protocol TCP --dst-port 2380:2380
openstack security group rule create k8s-master --protocol TCP --dst-port 10250:10250
openstack security group rule create k8s-master --protocol TCP --dst-port 10251:10251
openstack security group rule create k8s-master --protocol TCP --dst-port 10252:10252

openstack security group create k8s-node
openstack security group rule create k8s-node --protocol TCP --dst-port 10250:10250

# TODO Floating IP
# openstack floating ip create fbf9bcc6-cbaa-4c24-8d56-8010915a6494
# but how to find the Floating Network?
