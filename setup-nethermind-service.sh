# #!/bin/bash
USER=$1
PUBLIC_IP=$2
KEY_PATH=$3
CHAIN_NAME=$4
BRANCH_NAME=${5:-master}

if [ -z "$USER" ] || [ -z "$PUBLIC_IP" ] || [ -z "$KEY_PATH" ] || [ -z "$CHAIN_NAME" ] || [ -z "$BRANCH_NAME" ]
then
    echo "==> Missing parameters:"
    echo "====>   USER - Default user used to SSH into VM."
    echo "====>   PUBLIC_IP - Ipv4 Public address of the Virual Machine."
    echo "====>   KEY_PATH - An absolute path to the ssh key that will be used to connect with a VM."
    echo "====>   CHAIN_NAME - Ethereum network/chain/config name."
    echo "====>   BRANCH_NAME (Optional) - Nethermind Github repo branch. Default branch is 'master'."
    echo "==> Usage: ./setup-nethermind-service.sh PUBLIC_IP KEY_PATH CHAIN_NAME BRANCH_NAME"
    exit 1
else
    echo "==> Setting up system clock synchronization"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-sync-clock.yml

    echo "==> Setting up nethermind sudo user"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-user.yml

    echo "==> Securing SSH connection"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER ssh_user=nethermind ssh_identity_key=$KEY_PATH.pub" playbooks/secure-ssh.yml
    
    echo "==> Setting up Nethermind environment"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind nethermind_branch=$BRANCH_NAME" playbooks/setup-nethermind.yml

    echo "==> Setting up Nethermind systemd service and starting it"
    sed -i '' "s/NETHERMIND_CONFIG=.*/NETHERMIND_CONFIG=$CHAIN_NAME/" roles/nethermind-service/files/.env
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/start-nethermind.yml
    sed -i '' "s/NETHERMIND_CONFIG=.*/NETHERMIND_CONFIG=goerli_pruned/" roles/nethermind-service/files/.env
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