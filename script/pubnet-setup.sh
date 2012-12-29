#!/bin/bash

. $HOME/devstack/openrc
. $HOME/account-wrapper.sh

admin_admin quantum net-create pub1 --shared True
admin_admin quantum subnet-create --ip_version 4 pub1 192.168.200.0/24

admin_admin quantum net-list
admin_admin quantum subnet-list
demo_invis quantum net-list
