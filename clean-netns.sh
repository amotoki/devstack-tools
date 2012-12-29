#!/bin/bash

for ns in `ip netns list`; do
  sudo ip netns delete $ns
  echo "Removed network namespace $ns"
done
