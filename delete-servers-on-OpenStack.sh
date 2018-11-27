#!/bin/sh
set -e

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <NAME_PREFIX>"
  exit -1
fi
NAME_PREFIX=$1
set -x

openstack server delete $NAME_PREFIX-master
openstack server delete $NAME_PREFIX-node
