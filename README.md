# ansible-scripts
Ansible playbooks to setup Nethermind nodes on different chains.

##### Table of Contents
  * [Requirements](#requirements)
  * [SSH key](#ssh-key)
  * [Inventory](#inventory)
    + [Setup inventory](#setup-inventory)
  * [Setup Nethermind environment](#setup-nethermind-environment)
    + [Encrypt Nethermind secrets](#encrypt-nethermind-secrets)
    + [Run the Nethermind service](#run-the-nethermind-service)
    + [Update the Nethermind service](#update-the-nethermind-service)
    + [Utilities](#utilities)
      - [Time sync](#time-sync)
      - [Firewall](#firewall)
      - [Prometheus node-exporter](#prometheus-node-exporter)

## Requirements
Make sure you are using `python3.x` with Ansible. To check: `ansible --version`

## SSH key
Copy pem private key file as `.workspace/private.pem` to enable ssh through ansible.

## Inventory
Ansible manages hosts using `inventory.yml` file. Current setup has `nethermind` group name.

A group may have multiple IPs (hosts). Each Ansible command needs group name to be mentioned. Ansible runs the playbook on mentioned group's machines. Note that if you don't mention group name, Ansible will run playbook on all machines.

### Setup inventory

Add nethermind node's IP/host under nethermind group.

Example:
```
all:

  hosts:
    nethermind:
      ansible_host: 
        xxx.xxx.xx.xx: # <-- nethermind host public IP address
```

Note: By default the user to login is setup as `ubuntu` in `group_vars/all` file. If you have a specific user to be logged in with please change the username in this file.

To check if nodes are reachable, run following commands:

```
ansible nethermind -m ping
```

## Setup Nethermind environment

```
ansible-playbook -l nethermind playbooks/setup-nethermind.yml
```

### Encrypt Nethermind secrets

Fill the `roles/nethermind-service/files/secrets_file.enc` envs with desired values and encrypt the file.

```
ansible-vault encrypt roles/nethermind-service/files/secrets_file.enc
```

It will prompt you to create an ansible vault password.

Configure Nethermind's non-secret environment variables in `roles/nethermind-service/files/.env` file. This file will be consumed by the systemd service.

### Run the Nethermind service

You can change the Nethermind's source branch in `roles/build-nethermind/vars/main.yml` by changing the value of `nethermind_branch`.

Run the nethermind service while passing secrets file. It will prompt you to provide an ansible vault password.

```
ansible-playbook -l nethermind -e @roles/nethermind-service/files/secrets_file.enc --ask-vault-pass playbooks/start-nethermind.yml
```

### Update the Nethermind service

You can switch the Nethermind's source branch in `roles/update-nethermind/vars/main.yml` by changing the value of `nethermind_branch`.

```
ansible-playbook -l nethermind playbooks/update-nethermind.yml
```

### Utilities

#### Time sync

To setup a script that's sychronizing system clock

```
ansible-playbook -l nethermind playbooks/setup-sync-clock.yml
```

#### Firewall

To setup an ufw firewall with open ports on 8545, 9100, 30303 tcp/udp

```
ansible-playbook -l nethermind playbooks/setup-firewall.yml
```

#### Prometheus node-exporter

To setup the prometheus node-exporter

```
ansible-playbook -l nethermind playbooks/setup-node-exporter.yml
```
