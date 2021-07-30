# #!/bin/bash
USER=$1
PUBLIC_IP=$2
KEY_PATH=$3


if [ -z "$PUBLIC_IP" ] || [ -z "$KEY_PATH" ] || [ -z "$USER" ]
then
    echo "==> Missing parameters:"
    echo "====>   USER - Default user used to SSH into VM."
    echo "====>   PUBLIC_IP - Ipv4 Public address of the Virual Machine."
    echo "====>   KEY_PATH - An absolute path to the ssh key that will be used to connect with a VM."
    echo "==> Usage: ./setup-xdai-validator.sh PUBLIC_IP KEY_PATH"
    exit 1
else
    echo "==> Setting up system clock synchronization"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-sync-clock.yml

    echo "==> Setting up nethermind sudo user"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/setup-user.yml

    echo "==> Securing SSH connection"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER ssh_user=nethermind ssh_identity_key=$KEY_PATH.pub" playbooks/secure-ssh.yml

    echo "==> Setting up Nethermind docker environment and starting it"
    ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "chain=xdai ansible_user=nethermind" playbooks/setup-docker-compose.yml
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