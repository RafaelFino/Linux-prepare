#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Creating shares"
	ssh dev@$p "sudo apt install -y smbclient cifs-utils"
	ssh dev@$p "sudo mkdir /media/share-b"	
	ssh dev@$p "sudo mkdir /media/share-c"
	ssh dev@$p "sudo chmod 777 /media/share-b"
	ssh dev@$p "sudo chmod 777 /media/share-c"
	ssh dev@$p "sudo chown dev:dev /media/share-b"	
	ssh dev@$p "sudo chown dev:dev /media/share-c"	
	ssh dev@$p "echo '//192.168.1.8/share-b   /media/share-b  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab"
	ssh dev@$p "echo '//192.168.1.8/share-c   /media/share-c  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab"
	ssh dev@$p "sudo systemctl daemon-reload"
	ssh dev@$p "sudo mount -a"
	echo "<< $p - Done!"
done
echo "Done!"
