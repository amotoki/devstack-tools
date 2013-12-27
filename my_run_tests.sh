#!/bin/bash

VENV=.venv

if [ -n "$1" ]; then
  TEST=$1
  if ! echo $TEST | grep "neutron.tests.unit" > /dev/null; then
    TEST=neutron.tests.unit.$TEST
  fi
  TESTR_ARGS=--testr-args="$TEST"
fi

DIR=$(pwd)
while true; do
  if [ -d $DIR/.git ]; then
    break
  fi
  DIR=`dirname $DIR`
  if [ "$DIR" = "/" ]; then
    echo "neutron directory not found"
    exit 1
  fi
done
cd $DIR
echo "----> Running in $DIR"

if [ ! -d $VENV ]; then
  virtualenv $VENV
fi

source $VENV/bin/activate
unset http_proxy
unset https_proxy
export OS_DEBUG=1
(python setup.py testr --slowest $TESTR_ARGS; \
 ps auxw | grep -v grep | grep .testrepository/tmp | awk '{print $2;}' | xargs kill) &

sleep 1
LIMIT=10
while [ $LIMIT -gt 0 ]; do
  if ls -1 .testrepository | grep tmp > /dev/null; then
    break
  fi
  LIMIT=`expr $LIMIT - 1`
  sleep 1
done

#tail -f .testrepository/tmp* | grep --color=always --line-buffered -E '^(successful|failure):' | cat -n
tail -f .testrepository/tmp* | grep --color=always --line-buffered -E '^test:' | cat -n

echo
LASTLOG=$(ls -1tr .testrepository/[0-9]* | tail -1)
echo "-----------------------------------------------"
echo "Failed tests:"
grep failure: $LASTLOG
echo "-----------------------------------------------"
echo "Loaded plugin count:"
grep "Loading Plugin:" $LASTLOG | cut -d : -f 4 | sort | uniq -c
