#!/bin/bash

function usage() {
  cat >&2 <<EOF
Usage: $0 [-v] [-b BASEDIR] [git subcommand]
  If no subcommand is specified, 'branch' is invoked.
EOF
  exit 1
}

while getopts "b:dvh" flag; do
  case "$flag" in
    b) BASE="$OPTARG";;
    v) VERBOSE=1;;
    d) set -o xtrace;;
    h) usage;;
    \?) usage;;
  esac
done
shift $(( $OPTIND - 1 ))

function exec_branch_show() {
  local d=$1
  local p=$(pwd)
  local ref branch head base
  cd $d
  base=$(basename $d)

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

  cd $p
}

function exec_command() {
  local d=$1
  shift
  local p=$(pwd)
  cd $d
  echo "----- $d -----"
  git $*
  cd $p
}

for d in `find $BASE -type d -name .git | sort`; do
  d=$(dirname $d) # strip trailing "/.git"
  if [ -n "$1" ]; then
    exec_command $d $*
  else
    exec_branch_show $d
  fi
done
