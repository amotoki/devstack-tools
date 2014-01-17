#!/bin/bash -x

set -o errexit

echo $PPID > $WORKSPACE/gate.pid

export PYTHONUNBUFFERED=true

#export http_proxy=$PROXY
#export https_proxy=$PROXY

echo "Running devstack"
cd $DEST/devstack
./stack.sh

# Ensure to run all tests
set +o errexit

# It is required to pass Swift related tests
unset http_proxy
unset https_proxy

res=0
cd $DEST/tempest

if [ "$DEVSTACK_GATE_SMOKE_SERIAL" -eq "1" ]; then
  echo "Running tempest smoke tests"
  bash tools/pretty_tox_serial.sh '(?!.*\[.*\bslow\b.*\])((smoke)|(^tempest\.scenario)) {posargs}'
  [[ $? -eq 0 && $res -eq 0 ]]
  res=$?
fi
if [ "$DEVSTACK_GATE_TEMPEST_SCENARIO" -eq "1" ]; then
  echo "Running scenario tests"
  bash tools/pretty_tox_serial.sh 'tempest.scenario {posargs}'
  [[ $? -eq 0 && $res -eq 0 ]]
  res=$?
fi
if [ "$DEVSTACK_GATE_NETWORK_API" -eq "1" ]; then
  echo "Running network API tests"
  bash tools/pretty_tox_serial.sh 'tempest.api.network {posargs}'
  [[ $? -eq 0 && $res -eq 0 ]]
  res=$?
fi
if [ "$DEVSTACK_GATE_TEMPEST_API" -eq "1" ]; then
  echo "Running API tests"
  bash tools/pretty_tox_serial.sh 'tempest.api {posargs}'
  [[ $? -eq 0 && $res -eq 0 ]]
  res=$?
fi

exit $res
