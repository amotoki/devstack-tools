#!/bin/bash

if [ -f /home/ubuntu/.ssh/id_dsa.pub ]; then
  nova keypair-add --pub-key /home/ubuntu/.ssh/id_dsa.pub motoki-gemini
fi
