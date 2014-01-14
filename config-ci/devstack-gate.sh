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
#echo "Running tempest smoke tests"
#bash tools/pretty_tox_serial.sh '(?!.*\[.*\bslow\b.*\])((smoke)|(^tempest\.scenario)) {posargs}'
echo "Running API tests"
bash tools/pretty_tox_serial.sh 'tempest.api {posargs}'

res=$?
