#!/bin/bash

function exec_with_user {
  local _USER _TENANT
  _USER=$1
  _TENANT=$2
  shift 2
  echo OS_USERNAME=$_USER OS_TENANT_NAME=$_TENANT
  OS_USERNAME=$_USER OS_TENANT_NAME=$_TENANT $*
}

function admin_admin {
  exec_with_user admin admin $*
}

function admin_demo {
  exec_with_user admin demo $*
}

function demo_demo {
  exec_with_user demo demo $*
}

function demo_invis {
  exec_with_user demo invisible_to_admin $*
}
