#!/bin/bash -ex

BRIDGE=${BRIDGE:-br-int}
CONTROLLER=${CONTROLLER:-'tcp:192.168.16.254'}
HOST_IP_IFACE=eth0

function generate_dpid_from_ipv4_address() {
    local IFACE=$1
    local HOST_IP
    HOST_IP=$(LC_ALL=C /sbin/ifconfig ${IFACE} | grep -m 1 'inet addr' | cut -d: -f2 | awk '{print $1;}')
    HOST_IP_LAST=$(echo $HOST_IP | cut -d . -f 4)
    #DATAPATH_ID=$(printf "%016x\n" $HOST_IP_LAST)
    DATAPATH_ID=$(printf "%016d\n" $HOST_IP_LAST)
}

generate_dpid_from_ipv4_address $HOST_IP_IFACE

sudo ovs-vsctl add-br $BRIDGE
sudo ovs-vsctl br-set-external-id $BRIDGE bridge-id $BRIDGE
sudo ovs-vsctl set Bridge $BRIDGE other-config:datapath-id=$DATAPATH_ID
sudo ovs-vsctl set-fail-mode $BRIDGE secure
if [ -n "$CONTROLLER" ]; then
  sudo ovs-vsctl set-controller $BRIDGE $CONTROLLER
fi

echo "------------------------------"
sudo ovs-vsctl show
echo "------------------------------"
sudo ovs-ofctl show $BRIDGE
