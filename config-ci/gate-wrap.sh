#!/bin/sh -ex

CACHE_URL=http://10.56.45.207/openstack
PROXY=http://proxygate2.nic.nec.co.jp:8080

WORKDIR=`pwd`

DEST=/opt/stack
GITTAR=gitrepo.tgz
sudo rm -rf $DEST
sudo mkdir -p $DEST
sudo chown -R `whoami`: $DEST
cd $DEST
http_proxy= wget -O $GITTAR $CACHE_URL/$GITTAR
tar xzf $GITTAR -C $DEST
rm -f $GITTAR
for d in *; do
  cd $d
  https_proxy=$PROXY git pull
  cd ..
done

cd $WORKDIR
PIPTAR=pip.cache.tgz
http_proxy= wget -O $PIPTAR $CACHE_URL/$PIPTAR
tar xzf $PIPTAR
sudo mkdir -p /var/cache/pip
sudo mv pip.cache/* /var/cache/pip
sudo chown -R root:root /var/cache/pip
rm -rf pip.cache
rm -f $PIPTAR
