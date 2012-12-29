#!/bin/bash

IMAGE_NAME=tty-quantum

. $HOME/devstack/openrc
. $HOME/account-wrapper.sh

IMAGE_ID=$(nova image-list | grep $IMAGE_NAME | grep -vE '(kernel|ramdisk)' | awk '{print $2;}')

function get_netid {
    NAME=$1
    admin_admin quantum net-list -c id -- --name $1 | \
	grep -E '([a-f0-9]+-){4}[a-f0-9]+' | \
	awk '{print $2;}'
}

demo_demo nova boot --image $IMAGE_ID --flavor 1 --nic net-id=$(get_netid net1) net1
demo_invis nova boot --image $IMAGE_ID --flavor 1 --nic net-id=$(get_netid pub1) pub1
