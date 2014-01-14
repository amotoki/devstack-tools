#!/bin/bash -ex

set -o errexit

echo $PPID > $WORKSPACE/gate.pid

export PYTHONUNBUFFERED=true

#export http_proxy=$PROXY
#export https_proxy=$PROXY

echo "Running devstack"
cd $DEST/devstack
./stack.sh

unset http_proxy
unset https_proxy

cd $DEST/tempest
if [ "$DEVSTACK_GATE_SMOKE_SERIAL" -eq "1" ]; then
  echo "Running tempest smoke tests"
  bash tools/pretty_tox_serial.sh '(?!.*\[.*\bslow\b.*\])((smoke)|(^tempest\.scenario)) {posargs}'
  res=$?
elif [ "$DEVSTACK_GATE_NETWORK_API" -eq "1" ]; then
  echo "Running API tests"
  bash tools/pretty_tox_serial.sh 'tempest.api.network {posargs}'
  res=$?
elif [ "$DEVSTACK_GATE_TEMPEST_SCENARIO" -eq "1" ]; then
  echo "Running scenario tests"
  bash tools/pretty_tox_serial.sh 'tempest.scenario {posargs}'
  res=$?
fi

[[ $res -eq 0 ]]
exit $?
