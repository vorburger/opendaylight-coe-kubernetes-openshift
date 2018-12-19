# opendaylight-coe-kubernetes-openshift

Personal sandbox for http://OpenDaylight.org CoE Kubernetes OpenShift related stuff which may move "upstream" in due time.

## Kubernetes

The intended order of using these scripts is:

1. `build-COE.sh`
1. `prequisites-k8s-on-OpenStack.sh`
1. `setup-k8s-with-Flannel-on-OpenStack.sh`
1. `test.sh`
1. `switch-k8s-to-COE-on-OpenStack.sh`
1. `test.sh`
1. `clean-full-COE.sh`
1. `test.sh`
1. `delete-servers-on-OpenStack.sh`

The `setup-k8s-node-on-OpenStack.sh` is called by `setup-k8s-with-Flannel-on-OpenStack.sh`, but can also be manually used again to add additional nodes to the Kubernetes cluster.

The `setup-k8s-with-Flannel-on-OpenStack.sh` for a master with 2 nodes takes about 15-20 minutes.

### Tunnels

As [documented e.g. here](https://github.com/opendaylight/coe/blob/master/docs/setting-up-coe-dev-environment.rst#bring-up-pods-and-test-connectivity), Tunnels have to be created so that pods created on different worker nodes (minions) will be able to communicate with other:

Given:

    coe2-node2 private=192.168.0.14
    coe2-node1 private=192.168.0.22
    coe2-master private=192.168.0.23

do:

    [fedora@coe2-master ~]$ sudo ovs-vsctl set O . other_config:local_ip=192.168.0.23
    [fedora@coe2-node1 ~]$ sudo ovs-vsctl set O . other_config:local_ip=192.168.0.22
    [fedora@coe2-node2 ~]$ sudo ovs-vsctl set O . other_config:local_ip=192.168.0.14

    [fedora@coe2-master ~]$ sudo ovs-vsctl set O . external_ids:br-name=br-int
    [fedora@coe2-node1 ~]$ sudo ovs-vsctl set O . external_ids:br-name=br-int
    [fedora@coe2-node2 ~]$ sudo ovs-vsctl set O . external_ids:br-name=br-int

Some tips how to debug problems related to this:

    [fedora@coe2-node1 ~]$ sudo ovs-vsctl show
    b8e664a6-ec11-4260-b60d-79c0537b125e
        Manager "tcp:192.168.0.23:6640"
            is_connected: true
        Bridge br-int
            Controller "tcp:192.168.0.23:6653"
                is_connected: true
            Port br-int
                Interface br-int
                    type: internal
            Port "tun2cda4bde1f0"
                Interface "tun2cda4bde1f0"
                    type: vxlan
                    options: {key=flow, local_ip="192.168.0.22", remote_ip="192.168.0.14"}

    [fedora@coe2-node2 ~]$ sudo ovs-vsctl show
    c8f907d4-9948-417f-b9dc-ccd55b02fdc3
        Manager "tcp:192.168.0.23:6640"
            is_connected: true
        Bridge br-int
            Controller "tcp:192.168.0.23:6653"
                is_connected: true
            Port "tun587d241e202"
                Interface "tun587d241e202"
                    type: vxlan
                    options: {key=flow, local_ip="192.168.0.14", remote_ip="192.168.0.22"}

    opendaylight-user@root>tep:show-state
    Tunnel Name       Source-DPN        Destination-DPN   Source-IP         Destination-IP    Trunk-State  Transport Type
    -------------------------------------------------------------------------------------------------------------------------------------
    tun587d241e202    226598570203980   16108188218689    192.168.0.14      192.168.0.22      DOWN        VXLAN
    tun2cda4bde1f0    16108188218689    226598570203980   192.168.0.22      192.168.0.14      DOWN        VXLAN

    [fedora@coe2-node1 ~]$ ping -c 1 192.168.0.14
    PING 192.168.0.14 (192.168.0.14) 56(84) bytes of data.
    --- 192.168.0.14 ping statistics ---
    1 packets transmitted, 0 received, 100% packet loss, time 0ms

    [you@laptop]$ openstack security group rule create k8s-node --protocol ICMP

    [fedora@coe2-node1 ~]$ ping -c 1 192.168.0.14
    PING 192.168.0.14 (192.168.0.14) 56(84) bytes of data.
    64 bytes from 192.168.0.14: icmp_seq=1 ttl=64 time=0.361 ms
    --- 192.168.0.14 ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 0.361/0.361/0.361/0.000 ms

For the VXLAN-based Tunnel to work between the Node VMs, port 4789 needs to be open for UDP (not TCP!), note:

    [fedora@coe2-node1 ~]$ netstat -an | grep 4789
    udp        0      0 0.0.0.0:4789            0.0.0.0:*
    udp6       0      0 :::4789                 :::*

    [you@laptop]$ openstack security group rule create k8s-node --protocol UDP --dst-port 4789:4789 --remote-ip 192.168.0.0/24

    opendaylight-user@root>tep:show-state
    Tunnel Name       Source-DPN        Destination-DPN   Source-IP         Destination-IP    Trunk-State  Transport Type
    -------------------------------------------------------------------------------------------------------------------------------------
    tun2cda4bde1f0    16108188218689    226598570203980   192.168.0.22      192.168.0.14      UP          VXLAN
    tun587d241e202    226598570203980   16108188218689    192.168.0.14      192.168.0.22      UP          VXLAN

If ODL's data store is wiped and cold restarted, it may be neccessary to manually `ovs-vsctl del-port` the `tun-..` port.


## OpenShift

_TODO_
