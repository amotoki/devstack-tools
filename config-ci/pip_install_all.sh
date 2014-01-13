#!/bin/sh -x

REQUIREMENTS=$HOME/gitrepo/requirements/global-requirements.txt

pip_install (){
    HTTP_PROXY=$http_proxy HTTPS_PROXY=$https_proxy NO_PROXY=$no_proxy \
    pip install \
    --allow-external netifaces --allow-insecure netifaces \
    --allow-external psutil --allow-insecure psutil \
    --allow-external pysendfile --allow-insecure pysendfile \
    --allow-external pytidylib --allow-insecure pytidylib \
    $@
}

pip_install_multi() {
    echo "=================================================="
    echo "* Installing $@..."
    local req=`mktemp`
    for mod in "$@"; do
        grep ^$mod $REQUIREMENTS
    done | sort | uniq >$req
    cat $req
    pip_install --upgrade -r $req
    cat $req >>$TMPFILE
    rm -f $req
}

pip_install_others() {
    echo "=================================================="
    local remfile=`mktemp`
    local workfile=`mktemp`
    #for r in `grep -v '^#' $REQUIREMENTS | grep -v -f $TMPFILE | awk -F# '{print $1}'`; do
    #    echo "* Installing $r..."
    #    pip_install --upgrade $r
    #    echo
    #done
    grep -v '^#' $REQUIREMENTS | grep -v -f $TMPFILE | awk -F# '{print $1}' >$remfile
    local nol=`wc -l $remfile | awk '{print $1}'`
    local last
    for i in `seq 1 20 $nol`; do
        last=`expr $i + 19`
        sed -n "$i,${last}p" $remfile > $workfile
        echo "* Installing ${i}-${last}..."
	cat $workfile
        pip_install --upgrade -r $workfile
	echo
    done
    rm -f $remfile
    rm -f $workfile
}

check_all_dependencies() {
    echo "=================================================="
    echo "* Checking all dependencies..."
    pip_install -r $REQUIREMENTS
}

setup() {
    TMPFILE=`mktemp`
    which python
}

cleanup() {
    rm -f $TMPFILE
}

setup

pip_install_multi Django django-nose
pip_install_multi hacking flake8 pep8
pip_install_multi SQLAlchemy sqlalchemy-migrate
pip_install_multi WebOb pecan WebTest WSME docutils sphinx sphinxcontrib-httpdomain
pip_install_others
check_all_dependencies

cleanup
