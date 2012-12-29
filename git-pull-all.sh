#!/bin/bash

DIR=$(dirname $0)
BASE=${1-.}

for d in `find $BASE -type d -name .git | sort`; do
  d=$(dirname $d)
  p=$(pwd)
  cd $d
  echo "----- $d -----"
  git pull
  cd $p
done
