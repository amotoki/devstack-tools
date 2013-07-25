#!/bin/bash

. $HOME/devstack/openrc
. $HOME/account-wrapper.sh

admin_admin neutron net-create pub1 --shared True
admin_admin neutron subnet-create --ip_version 4 pub1 192.168.200.0/24

admin_admin neutron net-list
admin_admin neutron subnet-list
demo_invis neutron net-list
