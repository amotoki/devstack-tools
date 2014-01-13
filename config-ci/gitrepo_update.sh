#!/bin/sh -x

GITREPO_TARBALL=/var/www/openstack/gitrepo.tgz

TOP_DIR=`dirname $0`
. $TOP_DIR/functions.sh

WORKDIR=$HOME
cd $WORKDIR

sudo aptitude -y install git-core pbzip2

git_clone_or_pull https://git.openstack.org/openstack-infra/devstack-gate

PROJFILE=`mktemp`
grep '^PROJECTS=' devstack-gate/devstack-vm-gate-wrap.sh > $PROJFILE
unset PROJECTS
cat $PROJFILE
set +o xtrace
. $PROJFILE
set -o xtrace
mkdir -p gitrepo
cd gitrepo
for proj in $PROJECTS; do
    git_clone_or_pull https://git.openstack.org/$proj
done
rm -f $PROJFILE

sudo aptitude -y install apache2
sudo mkdir -p `dirname $GITREPO_TARBALL`
TMPDEST=`mktemp`
tar czf $TMPDEST *
chmod 644 $TMPDEST
sudo mv $TMPDEST $GITREPO_TARBALL
ls -l $GITREPO_TARBALL
