#!/bin/bash
sudo apt install -y smbclient cifs-utils
sudo mkdir /media/share-b
sudo mkdir /media/share-c
sudo mkdir /media/plataforma
sudo chmod 777 /media/share-b
sudo chmod 777 /media/share-c
sudo chmod 777 /media/plataforma
#sudo chown dev:dev /media/share-b
#sudo chown dev:dev /media/share-c
echo '//192.168.1.8/share-b   /media/share-b  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab
echo '//192.168.1.8/share-c   /media/share-c  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab
echo '//192.168.1.8/plataforma   /media/plataforma  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
