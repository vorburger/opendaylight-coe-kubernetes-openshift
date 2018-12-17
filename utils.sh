#!/bin/bash

get_private_IP() {
    local NAME=$1
    until openstack server list --name $NAME\$ | grep -q 'private='; do sleep 1 ; done
    until openstack server show $NAME | grep -q 'ACTIVE'; do sleep 1 ; done
    local IP=$(openstack server list --name $NAME\$ -c Networks --format value | sed 's/private=\([0-9.]\+\).*/\1/')
    echo $IP
    # ^^ NB Bash foo - must "echo" not "return" for non-numeric reply.
}
get_public_IP() {
    local NAME=$1
    until openstack server list --name $NAME\$ | grep -q 'private='; do sleep 1 ; done
    until openstack server list --name $NAME\$ -c Networks --format value | grep -q ', '; do sleep 1 ; done
    until openstack server show $NAME | grep -q 'ACTIVE'; do sleep 1 ; done
    local IP=$(openstack server list --name $NAME\$ -c Networks --format value | sed 's/private=\([0-9.]\+\), \([0-9.]\+\)/\2/')
    echo $IP
}
