#!/bin/bash

if [ "$1" == "-v" ]; then
  VERBOSE=1
  shift
fi

BASE=${1-.}
CWD=`pwd`

# import __git_ps1 function
source /etc/bash_completion.d/git

for d in `find $BASE -type d -name .git | sort`; do
  d=$(dirname $d) # strip trailing "/.git"
  pushd $d > /dev/null
  base=$(basename $d)
  #msg=`printf "%-30s: %%s" $base`
  #__git_ps1 "$msg"; echo
  if cat .git/HEAD | grep 'ref:' >/dev/null; then
    ref=$(git symbolic-ref HEAD)
    branch=${ref##refs/heads/}
    head=$(git show-branch --sha1-name $branch | cut -d ' ' -f 1)
  else
    branch=
    head=$(cat .git/HEAD)
  fi
  printf "%-30s: %s %s\n" $base $head $branch
  if [ -n "$VERBOSE" ]; then
    git branch | grep -vE "^\* $branch$"
  fi
  popd > /dev/null
done
