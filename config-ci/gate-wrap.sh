#!/bin/sh -ex

CACHE_URL=http://10.56.45.207/openstack
PROXY=http://proxygate2.nic.nec.co.jp:8080

WORKSPACE=${WORKSPACE:-$(pwd)}

# Set this to the time in minutes that the gate test should be allowed
# to run before being aborted (default 60).
export DEVSTACK_GATE_TIMEOUT=${DEVSTACK_GATE_TIMEOUT:-60}

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

cd $WORKSPACE
PIPTAR=pip.cache.tgz
http_proxy= wget -O $PIPTAR $CACHE_URL/$PIPTAR
tar xzf $PIPTAR
sudo mkdir -p /var/cache/pip
sudo mv pip.cache/* /var/cache/pip
sudo chown -R root:root /var/cache/pip
rm -rf pip.cache
rm -f $PIPTAR

REPO_URL=https://review.openstack.org
#GERRIT_PROJECT=openstack/neutron
#GERRIT_REFSPEC=refs/changes/01/66501/1
cd /opt/stack/$(basename $GERRIT_PROJECT)
https_proxy=$PROXY git fetch $REPO_URL/$GERRIT_PROJECT $GERRIT_REFSPEC && git checkout FETCH_HEAD

if ! function_exists "gate_hook"; then
  # the command we use to run the gate
  function gate_hook {
    timeout -s 9 ${DEVSTACK_GATE_TIMEOUT}m $BASE/new/devstack-gate/devstack-vm-gate.sh
  }
fi

export PYTHONUNBUFFERED=true
cd /opt/stack/devstack
cp $WORKSPACE/devstack-tools/config-ci/localrc .
cat localrc
./stack.sh
