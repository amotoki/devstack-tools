#!/bin/bash

IMAGE_NAME=tty-quantum
PREFIX="s"
MAX=${2:-10}

export OS_PASSWORD=${OS_PASSWORD:-usapro}
export OS_AUTH_URL=${OS_AUTH_URL:-http://127.0.0.1:5000/v2.0}
export OS_USERNAME=${OS_USERNAME:-demo}
export OS_TENANT_NAME=${OS_TENANT_NAME:-demo}
export OS_NO_CACHE=1

vm_boot() {
  IMAGE_ID=$(nova image-list | awk "{ if (\$4 == \"$IMAGE_NAME\") { print \$2; }}")

  I=$(nova list | grep -v ^+ | grep -v '| Status |' | awk '{print $4;}' | sed -e "s/^$PREFIX//" | sort -n | tail -1)
  I=`expr $I + 1`

  for x in `seq $MAX`; do
    echo "($x/$MAX)"
    name=$(printf "%s-%03d" $PREFIX $I)
    nova boot --image $IMAGE_ID --flavor 1 ${name}
    I=`expr $I + 1`
    sleep 1
  done
}

vm_delete() {
  local x=1
  VMs=$(nova list | grep -v ^+ | grep -v '| Status |' | awk '{print $2;}' | sort | head -$MAX)
  for vm in $VMs; do
    echo "($x/$MAX) Stopping an instance $vm..."
    #nova list
    nova delete $vm
    sleep 1
    x=`expr $x + 1`
  done
  #nova list
}

vm_list() {
  watch -d -n 1 nova list
}

vm_host() {
  nova-manage vm list 2>/dev/null | awk '{print $1,$2,$3,$4,$5;}'
}

case "$1" in
  boot)
    vm_boot
    vm_list
    ;;

  delete)
    vm_delete
    vm_list
    ;; 

  list)
    vm_list
    ;;

  host)
    vm_host
    ;;

  *)
    echo "$0 (boot|delete|list|host)"
    ;;

esac
