# Routing and Firewalls

Both the router and firewalls will use `nftables` which will run on proxmox host

## Usage
Install nftables

```sh 
sudo apt update \ 
    install nftables
```

Enable and start the nftables service.

```sh
sudo systemctl enable nftables
sudo systemctl start nftables 
```

This is nftables file for both routing and both the firewalls
> (File)[./setup.nft]

copy the contents of the file and paste in `/etc/nftables.conf`

Test for errors

```sh
sudo nft -c -f /etc/nftables.conf
```

Load the rule set

```sh
sudo nft -f /etc/nftables.conf
```

Verify the rule set

```sh
sudo nft list ruleset
```


### Routing 


### Firewalls
firewalls are used to control incoming and outgoing network traffic by allowing or blocking specific traffic based on pre-defined rules. It acts as a parimeter between a trusted and untrusted network, preventing malicious activity.

### Setting up firewall

In this lab I will be using `nftables` as my firewall. This will run on my proxmox host

> nftables is a linux kernel feature that provides packet filtering, network address translation, etc. 

Install nftables



In the lab I have 2 firewalls.
n   
##### firewall 1 
This firewall sits between the internet and demilitarized zone.

Lets name it Roman

```sh

```





##### firewall 2
This firewall sits between the demilitarized zone and the internal network

Lets name it Randy



