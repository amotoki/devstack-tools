#!/bin/bash -x

CACHE_URL=http://10.56.45.207/openstack
export PROXY=http://proxygate2.nic.nec.co.jp:8080
export DEST=/opt/stack

WORKSPACE=${WORKSPACE:-$(pwd)}

# Set this to the time in minutes that the gate test should be allowed
# to run before being aborted (default 60).
export DEVSTACK_GATE_TIMEOUT=${DEVSTACK_GATE_TIMEOUT:-60}

prepare_gitrepo() {
  GITTAR=gitrepo.tgz
  sudo rm -rf $DEST
  sudo mkdir -p $DEST
  sudo chown -R `whoami`: $DEST
  cd $DEST
  http_proxy= wget --no-verbose -O $GITTAR $CACHE_URL/$GITTAR
  tar xzf $GITTAR -C $DEST
  rm -f $GITTAR
  for d in *; do
    cd $d
    https_proxy=$PROXY git pull
    cd ..
  done
}

prepare_pipcache() {
  cd $WORKSPACE
  PIPTAR=pip.cache.tgz
  http_proxy= wget --no-verbose -O $PIPTAR $CACHE_URL/$PIPTAR
  tar xzf $PIPTAR
  sudo mkdir -p /var/cache/pip
  sudo mv pip.cache/* /var/cache/pip
  sudo chown -R root:root /var/cache/pip
  rm -rf pip.cache
  rm -f $PIPTAR
}

fetch_target_patchset() {
  REPO_URL=https://review.openstack.org
  #GERRIT_PROJECT=openstack/neutron
  #GERRIT_REFSPEC=refs/changes/01/66501/1
  cd $DEST/$(basename $GERRIT_PROJECT)
  https_proxy=$PROXY git fetch $REPO_URL/$GERRIT_PROJECT $GERRIT_REFSPEC && git checkout FETCH_HEAD
}

setup_devstack() {
  cp $WORKSPACE/devstack-tools/config-ci/localrc $DEST/devstack/localrc
  cat $DEST/devstack/localrc
}

if [ ! -n "$SKIP" ]; then
  prepare_gitrepo
  prepare_pipcache
fi
fetch_target_patchset
setup_devstack

if ! function_exists "gate_hook"; then
  # the command we use to run the gate
  function gate_hook {
    timeout -s 9 ${DEVSTACK_GATE_TIMEOUT}m $WORKSPACE/devstack-tools/config-ci/devstack-gate.sh
  }
fi

# Run the gate function
gate_hook
GATE_RETVAL=$?
RETVAL=$GATE_RETVAL

if [ $GATE_RETVAL -eq 137 ] && [ -f $WORKSPACE/gate.pid ] ; then
GATEPID=`cat $WORKSPACE/gate.pid`
    echo "Killing process group ${GATEPID}"
    sudo kill -s 9 -${GATEPID}
fi

exit $RETVAL
