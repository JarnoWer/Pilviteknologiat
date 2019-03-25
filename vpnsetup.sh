#!/bin/bash

#Copyright 2019 Miika Zitting & Jarno Wermundsen http://miikazitting.wordpress.com GPL 3
#Script to setup an Strongswan Ikev2 VPN server automatically

sudo apt-get update
sudo apt-get -y install strongswan strongswan-pki

mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki

#Creates 1024 bit certificate -> Windows cant handle any bigger

ipsec pki --gen --type rsa --size 1024 --outform pem > ~/pki/private/ca-key.pem

read -p "Give a name for your cert: " name

ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem     --type rsa --dn "CN=$name" --outform pem > ~/pki/cacerts/ca-cert.pem
ipsec pki --gen --type rsa --size 1024 --outform pem > ~/pki/private/server-key.pem

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

echo -e "config setup
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

#Add multiple new users with this loop

echo ': RSA "server-key.pem"' | sudo tee /etc/ipsec.secrets

read -p "Give username: " username
read -p "Give password: " password

echo "$username : EAP $password" | sudo tee -a /etc/ipsec.secrets

while true

do
    read -p "Do you want to add more users? [y/n] " answer

    [ "n" = "$answer" ] && break

    read -p "Give username: " username
    read -p "Give password: " password

    echo "$username : EAP $password" | sudo tee -a /etc/ipsec.secrets

done

sudo systemctl restart strongswan
sudo ufw allow ssh
sudo ufw enable
sudo ufw allow 500,4500/udp

interface=$(ip route | grep -Po "(dev \K[^ ]+)" | head -1)

#UFW before rules - Ugly but works

echo -e "#
# rules.before
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
#
*nat
-A POSTROUTING -s 10.10.10.0/24 -o $interface -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.10.10.0/24 -o $interface -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
COMMIT
# Don't delete these required lines, otherwise there will be errors
*filter
:ufw-before-input - [0:0]
:ufw-before-output - [0:0]
:ufw-before-forward - [0:0]
:ufw-not-local - [0:0]

-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT

# End required lines

# allow all on loopback
-A ufw-before-input -i lo -j ACCEPT
-A ufw-before-output -o lo -j ACCEPT

# quickly process packets for which we already have a connection
-A ufw-before-input -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-output -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-before-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# drop INVALID packets (logs these in loglevel medium and higher)
-A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
-A ufw-before-input -m conntrack --ctstate INVALID -j DROP

# ok icmp codes for INPUT
-A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-input -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT

# ok icmp code for FORWARD
-A ufw-before-forward -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-forward -p icmp --icmp-type echo-request -j ACCEPT

# allow dhcp client to work
-A ufw-before-input -p udp --sport 67 --dport 68 -j ACCEPT

#
# ufw-not-local
#
-A ufw-before-input -j ufw-not-local

# if LOCAL, RETURN
-A ufw-not-local -m addrtype --dst-type LOCAL -j RETURN

# if MULTICAST, RETURN
-A ufw-not-local -m addrtype --dst-type MULTICAST -j RETURN

# if BROADCAST, RETURN
-A ufw-not-local -m addrtype --dst-type BROADCAST -j RETURN

# all other non-local packets are dropped
-A ufw-not-local -m limit --limit 3/min --limit-burst 10 -j ufw-logging-deny
-A ufw-not-local -j DROP

# allow MULTICAST mDNS for service discovery (be sure the MULTICAST line above
# is uncommented)
-A ufw-before-input -p udp -d 224.0.0.251 --dport 5353 -j ACCEPT

# allow MULTICAST UPnP for service discovery (be sure the MULTICAST line above
# is uncommented)
-A ufw-before-input -p udp -d 239.255.255.250 --dport 1900 -j ACCEPT

# don't delete the 'COMMIT' line or these rules won't be processed

COMMIT

" | sudo tee /etc/ufw/before.rules


echo "net/ipv4/ip_forward=1
# Do not send ICMP redirects (we are not a router)
# Add the following lines
net/ipv4/conf/all/send_redirects=0
net/ipv4/ip_no_pmtu_disc=1
" | sudo tee -a /etc/ufw/sysctl.conf

sudo service ufw restart


cat /etc/ipsec.d/cacerts/ca-cert.pem >> certificate.pem
