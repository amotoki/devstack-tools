#!/bin/bash

TREMA_APPS_DIR=/opt/stack/trema/apps
TREMA_SS_DIR=$TREMA_SS_DIR/sliceable_switch
TREMA_TOPOLOGY_DIR=$TREMA_APPS_DIR/topology
TREMA_TMP=/opt/stack/data/trema/trema

TREMA_SS_SLICE_DB=/opt/stack/data/trema/sliceable_switch/db/slice.db
DEFAULT_NET=net1

TOP_DIR=$(dirname $0)
source $TOP_DIR/id-tool.sh

case "$1" in
  "list")
    cd $TREMA_SS_DIR
    sudo SLICE_DB_FILE=$TREMA_SS_SLICE_DB ./slice list
    ;;
  "show")
    cd $TREMA_SS_DIR
    NET=${2:-$DEFAULT_NET}
    NET_ID=$(get_net_id $NET)
    sudo SLICE_DB_FILE=$TREMA_SS_SLICE_DB ./slice show $NET_ID
    ;;
  "topology")
    cd $TREMA_TOPOLOGY_DIR
    TREMA_TMP=$TREMA_TMP trema run "./show_topology -G" | graph-easy
    ;;
  *)
    cat <<EOF
Usage: $0 command [args...]

Available Commands:
   list
   show <net_name>
   topology
EOF
  ;;
esac
