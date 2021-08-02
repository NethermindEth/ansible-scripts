# ansible-scripts
Ansible playbooks to setup Nethermind nodes on different chains.

##### Table of Contents
  - [Requirements](#requirements)
  - [Scripts](#scripts)
    * [Create SSH Key](#create-ssh-key)
    * [Deploy Nethermind docker-compose stack/systemd service](#deploy-nethermind-docker-compose-stack-systemd-service)
  - [Playbooks](#playbooks)
    * [Secure SSH](#secure-ssh)
    * [Setup nethermind user](#setup-nethermind-user)
    * [Setup docker-compose stack](#setup-docker-compose-stack)
    * [Setup nethermind environment for systemd service](#setup-nethermind-environment-for-systemd-service)
    * [Start nethermind systemd service](#start-nethermind-systemd-service)
    * [Update Nethermind](#update-nethermind)
    * [Utilities](#utilities)
      + [Clock sync](#clock-sync)
      + [Firewall](#firewall)
      + [Prometheus node-exporter](#prometheus-node-exporter)
      + [New Relic Agent](#new-relic-agent)
      + [Clean the environment](#clean-the-environment)

## Requirements
Make sure you are using `python3.x` with Ansible. To check: `ansible --version`

## Scripts
Scripts are the fastest way for deployment of the nethermind client.

### Create SSH Key

Create an ed25519 SSH key.

```bash
./create-ssh-key.sh [key_name]
```

### Deploy Nethermind docker-compose stack/systemd service

Run the `setup-nethermind.sh` script.

```bash
./setup-nethermind.sh help
```

The script will setup:
* system clock synchronization
* nethermind sudo user
* secure ssh connection (disabling root login)
* nethermind environment for either systemd service or docker-compose stack
* optionally install a New Relic agent

## Playbooks

Setup 3 variables:
`PUBLIC_IP` - comma separated list of VM's IPv4 addresses
`KEY_PATH` - path to private key which will be used for connection with VM
`USER` - default user used to SSH into VM

```bash
export PUBLIC_IP=127.0.0.1
export KEY_PATH=~/Work/ansible-scripts/.workspace/my_key
export USER=root
```

### Secure SSH

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER" playbooks/secure-ssh.yml
```

### Setup nethermind user

> **_NOTE:_** We are using 100 KDF rounds here. Decrypting a key with `-a 100` parameter will take ~1.5sec each time during ssh.

```bash
ssh-keygen -qa 100 -t ed25519 -C "your@emailaddress.com" -f .workspace/my_key_name
```

> **_NOTE:_** You might get prompted for a key passphrase if you set it up. Consider adding the identity to ssh agent with `ssh-add .workspace/my_key`

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=$USER ssh_user=nethermind ssh_identity_key=$KEY_PATH.pub" playbooks/setup-user.yml
```

### Setup docker-compose stack

If you wish to setup a docker-compose stack for `xDai Validator` you will need to add this variable to the ansible instructions below: `chain=xdai-validator`

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-docker-compose.yml
```

### Setup nethermind environment for systemd service

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-nethermind.yml
```

### Start nethermind systemd service

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/start-nethermind.yml
```

### Update Nethermind

Configure `branch=master` variable if you wish to run Nethermind from a different branch. 
It won't apply to docker-compose stack since we're not building the images there and only pulling them.

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind branch=master" playbooks/update-nethermind.yml
```

### Utilities

#### Clock sync

- [ ] To setup a script that's sychronizing system clock:

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-sync-clock.yml
```

#### Firewall

- [ ] To setup an ufw firewall with open ports on 8545, 9100, 30303 tcp/udp:

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-firewall.yml
```

#### Prometheus node-exporter

- [ ] To setup the prometheus node-exporter:

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-node-exporter.yml
```

#### New Relic Agent 

To install it use: 
```bash
ansible-galaxy collection install community.general
```

and then

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/setup-newrelic.yml
```

#### Clean the environment

```bash
ansible-playbook -i "$PUBLIC_IP," --private-key $KEY_PATH --extra-vars "ansible_user=nethermind" playbooks/clean.yml
```