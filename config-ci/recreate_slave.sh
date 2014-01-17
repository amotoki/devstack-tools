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
#VM_HOST=orion
HOST_USER=motoki

BASEIMG1=/home/motoki/easy_deploy/images/ubuntu1204-jenkins-raw.img
BASEIMG2=/home/motoki/kvm-img/jenkins_slave/ubuntu1204-jenkins-raw.img
IMGDIR=/home/motoki/kvm-img/jenkins_slave

jenkins_cli() {
  $JAVA -jar $CLIJAR "$@"
}

get_vm_host() {
  local host=$1
  cat <<EOF | grep $host | awk '{print $2}'
ostack03: orion
ostack04: orion
osci01:   ipdc03
osci02:   ipdc03
osci03:   ipdc04
osci04:   ipdc04
EOF
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
jenkins_cli offline-node $NAME -m "Recreating..."
jenkins_cli disconnect-node $NAME

VM_HOST=$(get_vm_host $NAME)
if [ ! -n "$VM_HOST" ]; then
  echo "[Error] No host found for VM $NAME."
  exit 1
fi
if [ "$VM_HOST" = "orion" ]; then
  BASEIMG=$BASEIMG1
else
  BASEIMG=$BASEIMG2
fi

host_exec virsh list
host_exec virsh destroy $NAME
host_exec ionice -c 2 -n 7 rm -f $IMGDIR/${NAME}.img
host_exec ionice -c 2 -n 7 cp $BASEIMG $IMGDIR/${NAME}.img
host_exec virsh start $NAME

timeout_exec ping -c 1 $NAME
timeout_exec ssh -o StrictHostKeyChecking=no jenkins@$NAME hostname
scp -o StrictHostKeyChecking=no /var/lib/jenkins/.ssh/id_rsa jenkins@${NAME}:/var/lib/jenkins/.ssh/id_rsa

jenkins_cli online-node $NAME
jenkins_cli connect-node $NAME
