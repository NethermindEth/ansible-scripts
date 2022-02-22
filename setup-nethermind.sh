#!/bin/bash
set -e

SCRIPT_NAME=${0##*/}
USER=$1
SERVICE_TYPE=$2
PUBLIC_IP=$3
KEY_PATH=$4
CHAIN_NAME=$5
BRANCH_NAME=${6:-master}


help() {
  echo "
Setup Nethermind Node with Systemd Service

Usage: $SCRIPT_NAME [user] [service_type] [ip] [ssh_key_path] [chain] [branch]
Example: $SCRIPT_NAME root systemd 127.0.0.1 /home/user/.ssh/my_key mainnet feature/nnm-cli

Arguments:
  user               Default user used to SSH into VM
  service_type       Whether run Nethermind as docker-compose stack [docker] or Systemd service [systemd]
  ip                 Ipv4 Public address of the Virual Machine
  ssh_key_path       An absolute path to the ssh key that will be used to connect with a VM
  chain              Ethereum network/chain/config name
  branch             Nethermind Github repo branch. Default branch is master
  *                  Help
"
  exit 1
}

if [ -z "$USER" ] || [ -z "$SERVICE_TYPE" ] || [ -z "$PUBLIC_IP" ] || [ -z "$KEY_PATH" ] || [ -z "$CHAIN_NAME" ]
then
    help
else
    echo "==> Setting up system clock synchronization"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-sync-clock.yml

    echo "==> Setting up nethermind sudo user"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-user.yml

    echo "==> Securing SSH connection"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER ssh_user=nethermind ssh_identity_key=$KEY_PATH.pub" playbooks/secure-ssh.yml
    
    if [ "$SERVICE_TYPE" == "systemd" ]; then
      echo "==> Setting up Nethermind environment"
      ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind nethermind_branch=$BRANCH_NAME" playbooks/setup-nethermind-apt.yml

      echo "==> Setting up Nethermind systemd service and starting it"
      sed -i '' "s/NETHERMIND_CONFIG=.*/NETHERMIND_CONFIG=$CHAIN_NAME/" roles/nethermind-service/files/.env
      ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/start-nethermind-apt.yml
      sed -i '' "s/NETHERMIND_CONFIG=.*/NETHERMIND_CONFIG=mainnet_pruned/" roles/nethermind-service/files/.env
    else
      echo "==> Setting up Nethermind docker-compose stack and starting it"
      sed -i '' "s/CONFIG=.*/CONFIG=$CHAIN_NAME/" roles/nethermind-docker-compose/files/common/.env.common
      ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-docker-compose.yml
      sed -i '' "s/CONFIG=.*/CONFIG=mainnet_pruned/" roles/nethermind-docker-compose/files/common/.env.common
    fi
fi

while true; do
    read -e -p "Do you wish to install New Relic Agent (License Key required)? (Y/n) " yn
    case $yn in
        [Yy]* ) read -e -s -p "Provide New Relic license key: " LICENSE_KEY
                ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind license_key=$LICENSE_KEY" playbooks/setup-newrelic.yml;
                break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done