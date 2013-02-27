#!/bin/bash

cat >> ~/.profile << 'EOF'

export PATH=$PATH:$HOME/tool
source $HOME/tool/id-tool.sh
source $HOME/tool/account-wrapper.sh
EOF

cat >> ~/.bashrc << 'EOF'

PROMPT_DIRTRIM=3
EOF
