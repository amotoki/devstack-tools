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
