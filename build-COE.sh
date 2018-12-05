#!/bin/bash
set -eu

if [ $# -ne 1 ]; then
  echo "USAGE: $0 <COE_DIR>"
  exit -1
fi
COE_DIR=$1
set -x

# https://github.com/opendaylight/coe/blob/master/docs/setting-up-coe-dev-environment.rst#building-coe-watcher-and-cni-plugin

pushd .

cd $COE_DIR/watcher
dep ensure -vendor-only
go build

cd $COE_DIR/odlCNIPlugin/odlovs-cni
dep ensure -vendor-only
go build

popd
