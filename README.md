# opendaylight-coe-kubernetes-openshift
Personal sandbox for http://OpenDaylight.org CoE Kubernetes OpenShift related stuff which may move "upstream" in due time

The intended order of using these scripts is:

1. `build-COE.sh`
1. `prequisites-k8s-on-OpenStack.sh`
1. `setup-k8s-with-Flannel-on-OpenStack.sh`
1. `test.sh`
1. `switch-k8s-to-COE-on-OpenStack.sh`
1. `test.sh`
1. `delete-servers-on-OpenStack.sh`

The `setup-k8s-node-on-OpenStack.sh` is called by `setup-k8s-with-Flannel-on-OpenStack.sh`, but can also be manually used again to add additional nodes to the Kubernetes cluster.
