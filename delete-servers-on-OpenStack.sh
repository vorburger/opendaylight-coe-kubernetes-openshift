#!/bin/sh
set -e

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <NAME_PREFIX>"
  exit -1
fi
NAME_PREFIX=$1
set -x

openstack server list -c Name --format value | grep ^$NAME_PREFIX- | xargs openstack server delete
