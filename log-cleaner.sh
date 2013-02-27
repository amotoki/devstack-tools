#!/bin/bash

echo "----- Removing devstack logs -----"
rm -vf /opt/stack/logs/*

echo "----- Removing Horizon apache logs -----"
sudo rm -vf /var/log/apache2/horizon_*
