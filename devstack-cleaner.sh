#!/bin/bash

DEVSTACK_DIR=$HOME/devstack
source $DEVSTACK_DIR/functions
source $DEVSTACK_DIR/stackrc

# Shutdown running VMs
VMLIST=$(virsh list | grep -E 'instance-[0-9a-fA-F]+' | awk '{print $2;}')
for vm in $VMLIST; do
  virsh destroy $vm
done
# Remove all VMs
VMLIST=$(virsh list --all | grep -E 'instance-[0-9a-fA-F]+' | awk '{print $2;}')
for vm in $VMLIST; do
  virsh undefine $vm
done
virsh list --all

# Remove all nwfilters created by nova-compute
NWFILTERS=$(virsh nwfilter-list | grep nova-instance-instance- | awk '{print $1;}')
for nwfilter in $NWFILTERS; do
  virsh nwfilter-undefine $nwfilter
done

# Stop running dnsmasq processes
if is_service_enabled q-dhcp; then
    pid=$(ps aux | awk '/[d]nsmasq.+interface=(tap|ns-)/ { print $2 }')
    [ ! -z "$pid" ] && sudo kill -9 $pid
fi

# Remove Hybrid ports
NETDEVS=$(ip -o link | cut -d : -f 2 | awk '{print $1;}' | grep ^qvo)
for p in $NETDEVS; do
  echo sudo ovs-vsctl del-port br-int $p
  sudo ovs-vsctl del-port br-int $p
  echo sudo ip link delete $p
  sudo ip link delete $p
done
BRIDGES=$(brctl show | grep -v 'bridge name' | awk '{print $1;}' | grep ^qbr)
for b in $BRIDGES; do
  echo sudo ifconfig $b down
  sudo ifconfig $b down
  echo sudo brctl delbr $b
  sudo brctl delbr $b
done

# Remove ovs-ports whose name is 'tap*****' or 'qr-*****'
for p in $(sudo ovs-vsctl list-ports br-int | grep -E '^(tap|qr-)'); do
  echo sudo ovs-vsctl del-port br-int $p
  sudo ovs-vsctl del-port br-int $p
done
for p in $(sudo ovs-vsctl list-ports br-ex | grep -E '^(tap|qg-)'); do
  echo sudo ovs-vsctl del-port br-ex $p
  sudo ovs-vsctl del-port br-ex $p
done

#/opt/stack/quantum/bin/quantum-netns-cleanup --verbose --force \
#  --config-file /etc/quantum/quantum.conf \
#  --config-file /etc/quantum/dhcp_agent.ini
for ns in `ip netns`; do
  sudo ip netns delete $ns
done

for br in `sudo ovs-vsctl list-br`; do
  sudo ovs-vsctl del-br $br
  echo ovs-vsctl del-br $br
done

TAPS=$(ip -o link | awk '{print $2;}' | cut -d : -f 1 | grep -E '^tap')
for i in $TAPS; do
  sudo ip link delete $i
  echo ip link delete $i
done

# Remove bridge created by linux bridge plugin
LBS=$(brctl show | grep -v 'bridge name' | awk '{print $1;}' | grep ^brq)
for br in $LBS; do
  sudo ifconfig $br down
  sudo brctl delbr $br
  echo brctl delbr $br
done

# devstack sometimes fails to talk with rabbitmq without stop and start.
sudo service rabbitmq stop
sudo service rabbitmq start

echo "=============================="
echo "Status"
echo "=============================="

brctl show
echo '---------'
sudo ovs-vsctl show
echo '---------'
ip link
echo '---------'
ip netns
