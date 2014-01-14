#!/bin/sh

CACHE_URL=http://10.56.45.207/openstack

WORKDIR=`pwd`

DEST=/opt/stack
GITTAR=gitrepo.tgz
sudo rm -rf $DEST
sudo mkdir -p $DEST
sudo chown -R `whoami`: $DEST
cd $DEST
http_proxy= wget -O $GITTAR $CACHE_URL/$GITTAR
tar xzf $GITTAR -C $DEST
for d in *; do
  cd $d
  git pull
  cd ..
done
rm -f $GITTAR

cd $WORKDIR
PIPTAR=pip.cache.tgz
http_proxy= wget -O $PIPTAR $CACHE_URL/$PIPTAR
tar xzf $PIPTAR
sudo mkdir -p /var/cache/pip
sudo mv pip.cache/* /var/cache/pip
sudo chown -R root:root /var/cache/pip
rm -rf pip.cache
rm -f $PIPTAR
