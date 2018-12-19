#!/bin/bash
set -eux

sudo ovs-vsctl show | grep "Port \"veth" | awk '{print $2}' | awk -F'"' '{print $2}' | xargs -d '\n' -L 1 sudo ovs-vsctl del-port

sudo ovs-vsctl show | grep "Port \"tun" | awk '{print $2}' | awk -F'"' '{print $2}' | xargs -d '\n' -L 1 sudo ovs-vsctl del-port
