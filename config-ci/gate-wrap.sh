#!/bin/bash -x

CACHE_URL=http://10.56.45.207/openstack
export PROXY=http://proxygate2.nic.nec.co.jp:8080
export DEST=/opt/stack

# Useful when runninng this script manually
WORKSPACE=${WORKSPACE:-$(pwd)}

TOP_DIR=`dirname $0`
. $TOP_DIR/functions.sh

# Make a directory to store logs
rm -rf logs
mkdir -p logs

# Set this to the time in minutes that the gate test should be allowed
# to run before being aborted (default 60).
export DEVSTACK_GATE_TIMEOUT=${DEVSTACK_GATE_TIMEOUT:-60}

setup_host &> $WORKSPACE/logs/devstack-gate-setup-host.txt
tail -10 $WORKSPACE/logs/devstack-gate-setup-host.txt

if ! function_exists "gate_hook"; then
  # the command we use to run the gate
  function gate_hook {
    timeout -s 9 ${DEVSTACK_GATE_TIMEOUT}m $WORKSPACE/devstack-tools/config-ci/devstack-gate.sh
  }
fi

# Run the gate function
gate_hook
GATE_RETVAL=$?
RETVAL=$GATE_RETVAL

if [ $GATE_RETVAL -eq 137 ] && [ -f $WORKSPACE/gate.pid ] ; then
GATEPID=`cat $WORKSPACE/gate.pid`
    echo "Killing process group ${GATEPID}"
    sudo kill -s 9 -${GATEPID}
fi

cleanup_host &> $WORKSPACE/logs/devstack-gate-cleanup-host.txt

exit $RETVAL
