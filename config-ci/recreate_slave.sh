#!/bin/bash -x

set -o errexit

if [ -z "$1" ]; then
  echo "Error: Node name must be specified."
  exit 1
fi
NAME=$1

export JENKINS_URL=http://ostack10.svp.cl.nec.co.jp/ci/

JAVA=/usr/bin/java
CLIJAR="jenkins-cli.jar"
VM_HOST=orion
HOST_USER=motoki

BASEIMG=/home/motoki/easy_deploy/images/ubuntu1204-jenkins-raw.img
IMGDIR=/home/motoki/kvm-img/jenkins_slave

jenkins_cli() {
  $JAVA -jar $CLIJAR "$@"
}

host_exec() {
  ssh ${HOST_USER}@$VM_HOST "$@"
}

timeout_exec() {
  set +o errexit
  i=0
  while [ $i -lt 24 ]; do
    "$@"
    [ $? -eq 0 ] && break
    i=`expr $i + 1`
    sleep 5
  done
  set -o errexit
}

if [ ! -f $CLIJAR ]; then
  curl -O $JENKINS_URL/jnlpJars/$CLIJAR
fi

jenkins_cli get-node $NAME
jenkins_cli offline-node $NAME
jenkins_cli disconnect-node $NAME

host_exec virsh list
host_exec virsh destroy $NAME
host_exec nice rm -f $IMGDIR/${NAME}.img
host_exec nice cp $BASEIMG $IMGDIR/${NAME}.img
host_exec virsh start $NAME

#timeout_exec ping -c 1 $NAME
#timeout_exec ssh -o StrictHostKeyChecking=no jenkins@$NAME hostname

jenkins_cli online-node $NAME
