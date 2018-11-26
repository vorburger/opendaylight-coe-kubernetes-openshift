#!/bin/sh
set -ex

openstack server delete odl-coe-k8s-master-fedora28
openstack server delete odl-coe-k8s-node1-fedora28
