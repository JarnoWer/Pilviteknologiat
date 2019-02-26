# StrongSwan asennus ja avainten luominen

Asennettiin vaadittavat  ohjelmisto
   sudo apt-get -y install strongswan moreutil iptables-persistent 

Tehtiin certifikaateille tarvittava kansio
   mkdir vpn-certs

Mentiin kansioon
   cd vpn-certs

Yritettiin luoda hallinnoija sertifikaattin avain ohjeen mukaan
   //ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem

Ei onnistunut nykyisin StrongSwan avaimen luontiin on eri ohjelma

Asennettiin StrongSwanin avaimen luonti ohjelma
   sudo apt-get -y install strongswan-pki 

4096 bittisen avaimen sai luotua
   ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem

Tähän avain tiedostoon laitettiin luku oikeus vain root käyttäjälle
   chmod 600 server-root-key.pem


Allekirjoitus nimen tekeminen ko. palvelimelle tapahtuu seuraavalla:
ipsec pki --self --ca --lifetime 3650 \
   --in server-root-key.pem \
   --type rsa --dn "C=GER, O=VPN Server, CN=VPN Server Root GER" \
   --outform pem > server-root-ca.pem

Luodaan avain VPN-serverille
ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem

Luodaan sertifikaatti ja allekirjoitus VPN-serverin ja hallinnojan sertifikaattien välille
   ipsec pki --pub --in vpn-server-key.pem \
   --type rsa | ipsec pki --issue --lifetime 1825 \
   --cacert server-root-ca.pem \
   --cakey server-root-key.pem \
   --dn "C=US, O=VPN Server, CN=server_name_or_ip" \
   --san server_name_or_ip \
   --flag serverAuth --flag ikeIntermediate \
   --outform pem > vpn-server-cert.pem

Kopioitiin näin tehty sertifikaatti ja avain ipsec.d ohjelman asteus kansioihin.
   sudo cp vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
   sudo cp vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem

 Lopuksi suojataan avain, että vain root voi lukea tiedostoja.
   sudo chown root /etc/ipsec.d/private/vpn-server-key.pem
   sudo chgrp root /etc/ipsec.d/private/vpn-server-key.pem
   sudo chmod 600 /etc/ipsec.d/private/vpn-server-key.pem

## StrongSwanin konfikurointi

StrongSwanin alkuperäisen asetus tiedoston voi tyhjätä kokonaan, esim. Nanolla.
sudo nano /etc/ipsec.conf

Syötetään config tiedostoon, että otetaan logia demonin tiloista ja sallittaan duplikaatti yhteydet.
config setup
  charondebug="ike 1, knl 1, cfg 0"
  uniqueids=no

Seuraavaksi tehdään ipsec.conf tiedostoon konfikuraatio asetukset VPN:lle. Kerromme StrongSwanille, että että luo IKEv2 VPN-tunnelit ja automaattisesti asettaa nämä asetukset:
conn ikev2-vpn
  auto=add
  compress=no
  type=tunnel
  keyexchange=ikev2
  fragmentation=yes
  forceencaps=yes

VPN-yhteyden salaus alkoritmi määritetään seuraavilla riveillä ipsec.conf tiedostoon saman conn ikev2-vpn kohdan alle.
ike=aes256-sha1-modp1024,3des-sha1-modp1024!
esp=aes256-sha1,3des-sha1!

Seuraavilla riveillä määritetään, että mikäli yhteys on poikki 300 sekuntia niin yhteys katkaistaan
dpdaction=clear
dpddelay=300s
rekey=no

## Tutustu näihin paremmin
Vasemman puolen konffi
  left=%any
  leftid=@server_name_or_ip
  leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
  leftsendcert=always
  leftsubnet=0.0.0.0/0

Oikean puole konffi
  right=%any
  rightid=%any
  rightauth=eap-mschapv2
  rightsourceip=10.10.10.0/24
  rightdns=8.8.8.8,8.8.4.4
  rightsendcert=never

StrongSwan kysyy käyttäjältä käyttäjätunnusta
  eap_identity=%identity

## Käyttäjätunnusten tekeminen StrongSwanille

Muokataan tiedostoa /etc/ipsec.secrets
Tiedostoon laitetaan ensin palvelimen tiedot:
   104.248.162.226 : RSA "/etc/ipsec.d/private/vpn-server-key.pem"

Sitten perään laitetaan käyttäjät ja käyttäjätunnukset
   testi1 %any% : EAP "salasana1"
   testi2 %any% : EAP "salasana2"

Tiedosto tallennetaan ja käynnistetään demoni uudelleen.
sudo ipsec reload

## Palomuurin konfikurointi ja kernel ip tunnelointi

Ensiksi UFW pois päältä, jos on käytössä.
   sudo ufw disable 

Poistetaan olemassa olevat säännöt.
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -F
    iptables -Z

Sallitaan olemassa olevat yhteydet ja tulevat ssh yhteydet porttiin 8888
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 8888 -j ACCEPT

Local lopback osoitteen yhteydet sallitaan.
   sudo iptables -A INPUT -i lo -j ACCEPT

Kerrotaan palomuurille, että IPSecin yhteydet sallitaan portit  500 ja 4500 
    sudo iptables -A INPUT -p udp --dport  500 -j ACCEPT
    sudo iptables -A INPUT -p udp --dport 4500 -j ACCEPT

IPtables ohjaa liikenteen ESPlle, joka tarjoaa lisäsuojaa.
    sudo iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.10/24 -j ACCEPT
    sudo iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.10/24 -j ACCEPT

VPN palvelin naamioi käyttäjien liikenteen näkymään niinkuin tulisivat VPN-palvelimelta.
    sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -j MASQUERADE

Estääksemme IP pakettien pirstaloitumisen määritämme fragmenttien maksimikoon pienemäksi.
    sudo iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.10/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

Kaikki ulkopuolinen liikenne tiputetaan
    sudo iptables -A INPUT -j DROP
    sudo iptables -A FORWARD -j DROP

Tallennetaan nämä asetukset reboot asetuksiksi
    sudo netfilter-persistent save
    sudo netfilter-persistent reload

Laitetaan etc/sysctl.conf tiedostoon seuraavat rivit:
  / Uncomment the next line to enable packet forwarding for IPv4
  net.ipv4.ip_forward=1

  . . .

  / Do not accept ICMP redirects (prevent MITM attacks)
  net.ipv4.conf.all.accept_redirects = 0
  / Do not send ICMP redirects (we are not a router)
  net.ipv4.conf.all.send_redirects = 0

  . . .
  / Effects on fragmentation
  net.ipv4.ip_no_pmtu_disc = 1

Näiden jälkeen palvelimen uudelleen käynnistys.
  sudo reboot

