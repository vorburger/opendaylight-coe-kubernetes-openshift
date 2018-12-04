#!/bin/bash

get_private_IP() {
    local NAME=$1
    local IP=$(openstack server list --name $NAME -c Networks --format value | sed 's/private=\([0-9.]\+\).*/\1/')
    # TODO check that $IP is not empty, wait longer if it is, eventually abandon
    echo $IP
    # ^^ NB Bash foo - must "echo" not "return" for non-numeric reply.
}
get_public_IP() {
    local NAME=$1
    local IP=$(openstack server list --name $NAME -c Networks --format value | sed 's/private=\([0-9.]\+\), \([0-9.]\+\)/\2/')
    # TODO check that $IP is not empty, wait longer if it is, eventually abandon
    echo $IP
}
