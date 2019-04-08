sudo ufw allow 22/tcp
read -p "Give username: " username
sudo ufw enable
sudo adduser $username
sudo adduser $username sudo
sudo adduser $username adm
sudo adduser $username admin
