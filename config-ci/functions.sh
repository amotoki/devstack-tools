# Required variables
#  CACHE_URL
#  PROXY
#  DEST
#  WORKSPACE
#  GERRIT_PROJECT
#  GERRIT_REFSPEC

GIT_TIMEOUT=10

git_clone_or_pull() {
    local url=$1
    local proj=`basename $url`
    if [ -d $proj ]; then
        cd $proj
        git pull
        cd ..
    else
        git clone $url
    fi
}

function function_exists {
    type $1 2>/dev/null | grep -q 'is a function'
}

prepare_gitrepo() {
  local GITTAR=gitrepo.tgz
  sudo rm -rf $DEST
  sudo mkdir -p $DEST
  sudo chown -R `whoami`: $DEST
  cd $DEST
  http_proxy= wget --no-verbose -O $GITTAR $CACHE_URL/$GITTAR
  tar xzf $GITTAR -C $DEST
  rm -f $GITTAR
  for d in *; do
    cd $d
    https_proxy=$PROXY timeout -s 9 ${GIT_TIMEOUT}m git pull
    cd ..
  done
}

prepare_pipcache() {
  cd $WORKSPACE
  local PIPTAR=pip.cache.tgz
  http_proxy= wget --no-verbose -O $PIPTAR $CACHE_URL/$PIPTAR
  tar xzf $PIPTAR
  sudo rm -rf /var/cache/pip
  sudo mv pip.cache /var/cache/pip
  sudo chown -R root:root /var/cache/pip
  rm -rf pip.cache
  rm -f $PIPTAR
}

fetch_target_patchset() {
  if [ -z "$GERRIT_PROJECT" ]; then
    return
  fi
  REPO_URL=${REPO_URL:-https://review.openstack.org}
  #GERRIT_PROJECT=openstack/neutron
  #GERRIT_REFSPEC=refs/changes/01/66501/1
  cd $DEST/$(basename $GERRIT_PROJECT)
  https_proxy=$PROXY timeout -s 9 ${GIT_TIMEOUT}m git fetch $REPO_URL/$GERRIT_PROJECT $GERRIT_REFSPEC && git checkout FETCH_HEAD
}

setup_devstack() {
  cp $WORKSPACE/devstack-tools/config-ci/localrc $DEST/devstack/localrc
  (cd $DEST/devstack && patch -p1 < $WORKSPACE/devstack-tools/config-ci/devstack.patch)
}

setup_syslog() {
  # Start with a fresh syslog
  sudo stop rsyslog
  sudo mv /var/log/syslog /var/log/syslog-pre-devstack
  sudo mv /var/log/kern.log /var/log/kern_log-pre-devstack
  sudo touch /var/log/syslog
  sudo chown /var/log/syslog --ref /var/log/syslog-pre-devstack
  sudo chmod /var/log/syslog --ref /var/log/syslog-pre-devstack
  sudo chmod a+r /var/log/syslog
  sudo touch /var/log/kern.log
  sudo chown /var/log/kern.log --ref /var/log/kern_log-pre-devstack
  sudo chmod /var/log/kern.log --ref /var/log/kern_log-pre-devstack
  sudo chmod a+r /var/log/kern.log
  sudo start rsyslog
}

setup_host() {
  setup_syslog
  prepare_gitrepo
  prepare_pipcache
  fetch_target_patchset
  setup_devstack
}

cleanup_host() {
  # Enabled detailed logging, since output of this function is redirected
  #set -o xtrace

  cd $WORKSPACE

  # Sleep to give services a chance to flush their log buffers.
  sleep 2

  local NEWLOGTARGET=$WORKSPACE/logs
  mkdir -p $NEWLOGTARGET/system
  sudo cp /var/log/syslog $WORKSPACE/logs/system/syslog.txt
  sudo cp /var/log/kern.log $WORKSPACE/logs/system/kern_log.txt
  sudo cp /var/log/apache2/horizon_error.log $WORKSPACE/logs/horizon_error.log
  mkdir $WORKSPACE/logs/rabbitmq/
  sudo cp /var/log/rabbitmq/* $WORKSPACE/logs/rabbitmq/
  mkdir -p $WORKSPACE/logs/sudo/sudoers.d/
  sudo cp /etc/sudoers.d/* $WORKSPACE/logs/sudo/sudoers.d/
  sudo cp /etc/sudoers $WORKSPACE/logs/sudo/sudoers.txt

  local BASE=/opt/stack
  mkdir -p $NEWLOGTARGET/devstack
  for f in $BASE/logs/screen-*.*.log; do
      # Guess symlink filename
      lf=$(echo $f | cut -d . -f 1,3)
      # Sometimes symlink is not updated, so if symlink does not exist
      # (or refers to another file), copy the original file.
      sudo cmp $f $lf >/dev/null 2>&1 || lf=$f
      sudo cp $lf $NEWLOGTARGET/devstack
  done
  sudo cp $BASE/logs/devstack.log $NEWLOGTARGET/
  sudo cp $BASE/devstack/localrc $WORKSPACE/logs/localrc.txt

  sudo iptables-save > $WORKSPACE/logs/system/iptables.txt
  df -h> $WORKSPACE/logs/system/df.txt

  pip freeze > $WORKSPACE/logs/system/pip-freeze.txt

  sudo cp -a $BASE/data/trema/trema/log $WORKSPACE/logs/trema
  sudo cp /var/log/apache2/sliceable_switch_*.log $WORKSPACE/logs/trema
  sudo cp -a /var/log/openvswitch $WORKSPACE/logs/openvswitch

  # Process testr artifacts.
  if [ -f $BASE/tempest/.testrepository/0 ]; then
      sudo cp $BASE/tempest/.testrepository/0 $WORKSPACE/subunit_log.txt
      #sudo python /usr/local/jenkins/slave_scripts/subunit2html.py $WORKSPACE/subunit_log.txt $WORKSPACE/testr_results.html
      sudo python $WORKSPACE/devstack-tools/config-ci/subunit2html.py $WORKSPACE/subunit_log.txt $WORKSPACE/testr_results.html
      sudo gzip -9 $WORKSPACE/subunit_log.txt
      sudo gzip -9 $WORKSPACE/testr_results.html
      sudo chown jenkins:nogroup $WORKSPACE/subunit_log.txt.gz $WORKSPACE/testr_results.html.gz
      sudo chmod a+r $WORKSPACE/subunit_log.txt.gz $WORKSPACE/testr_results.html.gz
  elif [ -f $BASE/tempest/.testrepository/tmp* ]; then
      # If testr timed out, collect temp file from testr
      sudo cp $BASE/tempest/.testrepository/tmp* $WORKSPACE/subunit_log.txt
      sudo gzip -9 $WORKSPACE/subunit_log.txt
      sudo chown jenkins:nogroup $WORKSPACE/subunit_log.txt.gz
      sudo chmod a+r $WORKSPACE/subunit_log.txt.gz
  fi

  if [ -f $BASE/tempest/tempest.log ] ; then
      sudo cp $BASE/tempest/tempest.log $WORKSPACE/logs/tempest.log
  fi

  # Make sure jenkins can read all the logs
  sudo chown -R jenkins:nogroup $WORKSPACE/logs/
  sudo chmod a+r $WORKSPACE/logs/

  rename 's/\.log$/.txt/' $WORKSPACE/logs/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/system/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/devstack/*
  rename 's/(.*)/$1.txt/' $WORKSPACE/logs/sudo/*
  rename 's/(.*)/$1.txt/' $WORKSPACE/logs/sudo/sudoers.d/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/rabbitmq/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/openvswitch/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/trema/*

  mv $WORKSPACE/logs/rabbitmq/startup_log \
     $WORKSPACE/logs/rabbitmq/startup_log.txt

  # Compress all text logs
  find $WORKSPACE/logs -iname '*.txt' -execdir gzip -9 {} \+
  find $WORKSPACE/logs -iname '*.dat' -execdir gzip -9 {} \+

  # Save the tempest nosetests results
  #sudo cp $BASE/tempest/nosetests*.xml $WORKSPACE/
  #sudo chown jenkins:jenkins $WORKSPACE/nosetests*.xml
  #sudo chmod a+r $WORKSPACE/nosetests*.xml

  # Disable detailed logging as we return to the main script
  #set +o xtrace
}
