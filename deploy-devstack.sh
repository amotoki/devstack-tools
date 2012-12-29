#!/bin/bash

shopt -s xtrace

TOP_DIR=$(cd $(dirname "$0") && pwd)

DEVSTACK_DIR=$HOME/devstack
DEVSTACK_REPO=git://orion.spf.cl.nec.co.jp/git/openstack/devstack.git

case "$1" in
"folsom")
  git clone -b stable/folsom $DEVSTACK_REPO $DEVSTACK_DIR
  cp -iv $TOP_DIR/config/localrc $DEVSTACK_DIR
  ;;
""|"trunk")
  git clone $DEVSTACK_REPO $DEVSTACK_DIR
  cp -iv $TOP_DIR/config/localrc $DEVSTACK_DIR
  ;;
esac
