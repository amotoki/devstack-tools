#!/bin/sh -x

PROXY=http://proxygate2.nic.nec.co.jp:8080
export http_proxy=$PROXY
export https_proxy=$PROXY

TOP_DIR=`dirname $0`
$TOP_DIR/gitrepo_update.sh
$TOP_DIR/pip_cache_update.sh
