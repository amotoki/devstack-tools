#!/bin/bash

unset http_proxy
unset https_proxy
unset no_proxy

./run_tests.sh "$@"
