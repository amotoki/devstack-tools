#!/bin/bash

UUID_PATTERN='[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-z]{12}'

for vmid in $(nova list | grep -E "$UUID_PATTERN" | awk '{print $2;}'); do
  nova delete $vmid
  echo "Delete instance $vmid"
  sleep 1
done
