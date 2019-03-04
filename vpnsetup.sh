-#!/bin/bash

#Copyright 2019 Miika Zitting & Jarno Wermundsen http://miikazitting.wordpress.com GPL 3
#Script to setup of a liveusb and set it up as a slave for master

sudo apt-get update
sudo apt-get -y install strongswan strongswan-pki

mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki

ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem

read -p "Give a name for your cert: " name

ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem     --type rsa --dn "CN=$name" --outform pem > ~/pki/cacerts/ca-cert.pem
ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem

read -p "Give the IP for your server: " ipaddress

ipsec pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | ipsec pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=$name" --san "$ipaddress" \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  ~/pki/certs/server-cert.pem

sudo cp -r ~/pki/* /etc/ipsec.d/
sudo mv /etc/ipsec.conf{,.original}

echo "config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$ipaddress
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity" | sudo tee /etc/ipsec.conf

read -p "Give a username for your VPN account: " username
read -p "Give a password for your VPN account: " password


echo ': RSA "server-key.pem"' | sudo tee /etc/ipsec.secrets
echo "$username : EAP $password" | sudo tee -a /etc/ipsec.secrets

sudo systemctl restart strongswan
sudo ufw allow ssh
sudo ufw enable
sudo ufw allow 500,4500/udp

interface=`ip route | grep -Po "(dev \K[^ ]+)" | head -1`

echo '*nat
-A POSTROUTING -s 10.10.10.0/24 -o $interface -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.10.10.0/24 -o $interface -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o $interface -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
COMMIT

-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT

' | sudo tee -a /etc/ufw/before.rules

echo 'net/ipv4/ip_forward=1
# Do not send ICMP redirects (we are not a router)
# Add the following lines
net/ipv4/conf/all/send_redirects=0
net/ipv4/ip_no_pmtu_disc=1
' | sudo tee -a /etc/ufw/sysctl.conf

sudo systemctl restart restart

cat /etc/ipsec.d/cacerts/ca-cert.pem >> certificate.pem
