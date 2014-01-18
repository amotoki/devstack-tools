#!/bin/bash -x

CACHE_URL=http://10.56.45.207/openstack
export PROXY=http://proxygate2.nic.nec.co.jp:8080
export DEST=/opt/stack

LOG_HOST=motoki@orion
LOG_PATH=tmp/jenkins-log

# Useful when runninng this script manually
WORKSPACE=${WORKSPACE:-$(pwd)}

# Make a directory to store logs
rm -rf logs
mkdir -p logs

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
  REPO_URL=https://review.openstack.org
  #GERRIT_PROJECT=openstack/neutron
  #GERRIT_REFSPEC=refs/changes/01/66501/1
  cd $DEST/$(basename $GERRIT_PROJECT)
  https_proxy=$PROXY git fetch $REPO_URL/$GERRIT_PROJECT $GERRIT_REFSPEC && git checkout FETCH_HEAD
}

setup_devstack() {
  cp $WORKSPACE/devstack-tools/config-ci/localrc $DEST/devstack/localrc
  (cd $DEST/devstack && patch -p1 < $WORKSPACE/devstack-tool/config-ci/devstack.patch)
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

  sudo cp /var/log/syslog $WORKSPACE/logs/syslog.txt
  sudo cp /var/log/kern.log $WORKSPACE/logs/kern_log.txt
  sudo cp /var/log/apache2/horizon_error.log $WORKSPACE/logs/horizon_error.log
  mkdir $WORKSPACE/logs/rabbitmq/
  sudo cp /var/log/rabbitmq/* $WORKSPACE/logs/rabbitmq/
  mkdir $WORKSPACE/logs/sudoers.d/

  sudo cp /etc/sudoers.d/* $WORKSPACE/logs/sudoers.d/
  sudo cp /etc/sudoers $WORKSPACE/logs/sudoers.txt

  local NEWLOGTARGET=$WORKSPACE/logs
  local BASE=/opt/stack
  sudo cp $BASE/logs/screen-* $NEWLOGTARGET/
  sudo cp $BASE/logs/devstack.log $NEWLOGTARGET/
  sudo cp $BASE/devstack/localrc $WORKSPACE/logs/localrc.txt

  sudo iptables-save > $WORKSPACE/logs/iptables.txt
  df -h> $WORKSPACE/logs/df.txt

  pip freeze > $WORKSPACE/logs/pip-freeze.txt

  sudo cp -a $BASE/data/trema/trema/log $WORKSPACE/logs/trema
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
  rename 's/(.*)/$1.txt/' $WORKSPACE/logs/sudoers.d/*
  rename 's/\.log$/.txt/' $WORKSPACE/logs/rabbitmq/*

  mv $WORKSPACE/logs/rabbitmq/startup_log \
     $WORKSPACE/logs/rabbitmq/startup_log.txt

  # Remove duplicate logs
  rm $WORKSPACE/logs/*.*.txt

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

send_logs() {
  cd $WORKSPACE
  scp -o StrictHostKeyChecking=no -r logs $LOG_HOST:$LOG_PATH/$JOB_NAME/$BUILD_NUMBER
  scp -o StrictHostKeyChecking=no subunit_log.txt.gz testr_results.html.gz $LOG_HOST:$LOG_PATH/$JOB_NAME/$BUILD_NUMBER
}

setup_host

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

cleanup_host
send_logs

exit $RETVAL
