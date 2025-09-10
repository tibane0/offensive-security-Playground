#!/bin/bash

ip_addr="172.168.1.10/24"
gateway="172.16.1.1"
passwd="passwd"
hostname="DMZ SERVER"
ID=410


pct create $ID \
storage-disk:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
--storage storage-disk \
--hostname $hostname \
--memory 600 \
--rootfs storage-disk:40 \
--cores 1 \
--net0 name=eth0,bridge=vmbr1,ip=$ip_addr,gw=$gateway \
--password $passed
