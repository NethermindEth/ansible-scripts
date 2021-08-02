#!/bin/bash

KEY_NAME=$1

if [ -z "$KEY_NAME" ]
then
    echo "==> Missing parameters:"
    echo "====>   KEY_NAME - Name of the ssh key"
    echo "==> Usage: ./create-ssh-key.sh KEY_NAME"
    exit 1
else
    ssh-keygen -qa 100 -t ed25519 -C "devops@nethermind.io" -f .workspace/$KEY_NAME -q -N ""
    ssh-add .workspace/$KEY_NAME
fi
