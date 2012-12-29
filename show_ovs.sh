#!/bin/sh

VSCTL="sudo ovs-vsctl"
OFCTL="sudo ovs-ofctl"

if [ "$1" = "detail" ]; then
  echo "--------------------"
  $VSCTL show
  echo "--------------------"
  $OFCTL show br-int
else
  for br in `$VSCTL list-br`; do
    echo "---------- $br ----------"
    $VSCTL list-ports $br
  done
fi
