#!/bin/bash

UUID_RE='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

#------------------------------------------------------------

function get_id_from_list {
    echo `"$@" | grep -E $UUID_RE | awk '{print $2;}'`
}

function get_id {
    echo `"$@" | awk '/ id / { print $4 }'`
}

function get_id_by_name {
    local name=$1
    shift
    "$@" | awk "{if (\$4 == \"$name\") { print \$2; }}"
}

function check_name {
    local funcname=$1
    local name=$2
    if [ -z "$name" ]; then
        echo "Usage: $funcname <name>"
        return 1
    fi
    return 0
}

function get_image_id {
    local name=$1
    check_name get_image_id $name || return
    get_id_by_name $name nova image-list
}

function get_net_id {
    local name=$1
    check_name get_net_id $name || return
    netid=$(get_id_by_name $name neutron net-list -c id -c name)
    echo $netid
}

function get_netns_dhcp {
    local name=$1
    check_name get_netns_dhcp $name || return
    netid=$(get_net_id $name)
    if [ -n "$netid" ]; then
        echo "qdhcp-$netid"
    fi
}

function get_netns_router {
    local name=$1
    check_name get_netns_router $name || return
    routerid=$(get_id_by_name $name neutron router-list -c id -c name)
    if [ -n "$routerid" ]; then
        echo "qrouter-$routerid"
    fi
}

function get_netns {
    local name=$1
    check_name get_netns $name || return
    ret=$(get_netns_dhcp $name)
    if [ -n "$ret" ]; then
        echo $ret
        return
    fi
    ret=$(get_netns_router $name)
    if [ -n "$ret" ]; then
        echo $ret
        return
    fi
}

function netns_exec {
    local name=$1
    shift
    netns=$(get_netns $name)
    if [ -z "$netns" ]; then
        echo "netns not found"
        return 1
    fi
    echo "Executing command in $netns"
    echo "----------------"
    sudo ip netns exec $netns $*
}
