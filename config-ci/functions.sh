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

export JENKINS_URL=http://ostack10.svp.cl.nec.co.jp/ci/
JAVA=/usr/bin/java
CLIJAR=${WORKSPACE:-$(pwd)}/jenkins-cli.jar

jenkins_cli() {
  [ -f $CLIJAR ] || wget --no-verbose -O $CLIJAR $JENKINS_URL/jnlpJars/$(basename $CLIJAR)
  $JAVA -jar $CLIJAR "$@"
}
