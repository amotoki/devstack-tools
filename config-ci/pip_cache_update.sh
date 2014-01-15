#!/bin/bash -ex

WORKDIR=$HOME
VENV=venv
PIP_CACHE_TARBALL=/var/www/openstack/pip.cache.tgz

TOP_DIR=$(cd $(dirname $0); pwd)
. $TOP_DIR/functions.sh

cd $WORKDIR
git_clone_or_pull https://github.com/amotoki/devstack-tools
git_clone_or_pull https://git.openstack.org/openstack-dev/devstack
cp devstack-tools/config-ci/localrc gitrepo/devstack/localrc
cd devstack
./tools/install_pip.sh
which virtualenv || sudo pip install virtualenv
rm -rf /tmp/pip_build_ubuntu

# Install dependent packages
sudo aptitude -y install python-dev libffi-dev libsasl2-dev libldap2-dev libmysqlclient-dev libpq-dev

cd $WORKDIR
export PIP_DOWNLOAD_CACHE=$WORKDIR/pip.cache
[ ! -d $VENV ] && virtualenv $VENV
. $VENV/bin/activate
$TOP_DIR/pip_install_all.sh
deactivate

sudo aptitude -y install apache2
sudo mkdir -p `dirname $PIP_CACHE_TARBALL`
cd `dirname $PIP_DOWNLOAD_CACHE`
TMPDEST=`mktemp`
tar czf $TMPDEST `basename $PIP_DOWNLOAD_CACHE`
chmod 644 $TMPDEST
sudo mv $TMPDEST $PIP_CACHE_TARBALL
ls -l $PIP_CACHE_TARBALL
