#!/bin/bash

. $TOP_DIR/openrc demo demo
if [ -f /home/ubuntu/.ssh/id_dsa.pub ]; then
  nova keypair-add --pub-key /home/ubuntu/.ssh/id_dsa.pub motoki-gemini
fi
