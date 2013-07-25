#!/bin/bash

. $HOME/devstack/openrc

IMAGE_NAME=tty-quantum

UUID_RE='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

#------------------------------------------------------------

function get_id_from_list {
    echo `"$@" | grep -E $UUID_RE | awk '{print $2;}'`
}

function get_id {
    echo `"$@" | awk '/ id / { print $4 }'`
}

function get_image_id {
  local name=$1
  nova image-list | awk "{if (\$4 == \"$name\") { print \$2; }}"
}

#------------------------------------------------------------

function exec_with_user {
  local _USER _TENANT
  _USER=$1
  _TENANT=$2
  shift 2
  echo OS_USERNAME=$_USER OS_TENANT_NAME=$_TENANT
  OS_USERNAME=$_USER OS_TENANT_NAME=$_TENANT $*
}

function admin_admin {
  exec_with_user admin admin $*
}

function admin_demo {
  exec_with_user admin demo $*
}

function demo_demo {
  exec_with_user demo demo $*
}

function demo_invis {
  exec_with_user demo invisible_to_admin $*
}

#------------------------------------------------------------

# (Created by devstack)
#demo_demo neutron net-create net1
#demo_demo neutron subnet-create --gateway 192.168.57.254 --name subnet1 net1 192.168.57.0/24
_net1_id=$(get_id_from_list demo_demo neutron net-list -c id)
_subnet1_id=$(get_id_from_list demo_demo neutron subnet-list -c id)
demo_demo neutron subnet-update $_subnet1_id --name subnet1

_net2_id=$(get_id demo_invis neutron net-create net2)
_subnet2_id=$(get_id demo_invis neutron subnet-create --name subnet2 net2 192.168.60.0/24)

_floating_net_id=$(get_id admin_admin neutron net-create floating-net --shared True)
_floating_subnet_id=$(get_id admin_admin neutron subnet-create floating-net 10.56.0.0/24 --name subnet-pub --enable_dhcp False)

demo_demo neutron router-create router1
demo_demo neutron router-interface-add router1 subnet1
demo_demo neutron router-gateway-set router1 floating-net

demo_invis neutron router-create router2
demo_invis neutron router-interface-add router2 subnet2
demo_invis neutron router-gateway-set router2 floating-net

admin_admin neutron port-list -c id -c device_owner -c fixed_ips
admin_admin neutron net-list -c id -c name -c tenant_id -c subnets -c shared

echo "net1 id =" $_net1_id
echo "net2 id =" $_net2_id
echo "floating net id =" $_floating_net_id

#------------------------------------------------------------

IMAGE_ID=$(get_image_id tty-neutron)
echo $IMAGE_ID

demo_demo nova boot --image $IMAGE_ID --flavor 1 --nic net-id=$_net1_id s1
demo_invis nova boot --image $IMAGE_ID --flavor 1 --nic net-id=$_net2_id s2

sleep 5
demo_demo nova list
demo_invis nova list

_p1_id=$(get_id_from_list demo_demo neutron port-list -c id -- --device_owner compute:nova)
_p2_id=$(get_id_from_list demo_invis neutron port-list -c id -- --device_owner compute:nova)

#------------------------------------------------------------

_fip1_id=$(get_id demo_demo neutron floatingip-create $_floating_net_id)
demo_demo neutron floatingip-associate $_fip1_id $_p1_id

_fip2_id=$(get_id demo_invis neutron floatingip-create $_floating_net_id)
demo_invis neutron floatingip-associate $_fip2_id $_p2_id

demo_demo neutron port-list -c id -c device_owner -c fixed_ips
demo_invis neutron port-list -c id -c device_owner -c fixed_ips

#------------------------------------------------------------

sudo ip addr add 10.56.0.200/24 dev br-ex
sudo ip link set br-ex up
