#!/bin/bash

set -o xtrace

TOP_DIR=$(cd $(dirname "$0") && pwd)

DEVSTACK_DIR=$HOME/devstack
DEVSTACK_REPO=https://github.com/openstack-dev/devstack.git

if [ -d $DEVSTACK_DIR ]; then
  cd $DEVSTACK_DIR
  git pull
else
  git clone $DEVSTACK_REPO $DEVSTACK_DIR
  cp -iv $TOP_DIR/config/localrc $DEVSTACK_DIR
fi
