#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Creating shares"
	ssh dev@$p "sudo apt install -y nfs-common"
	#ssh dev@$p "sudo chmod 777 /media/share"
	#ssh dev@$p "sudo chown dev:dev /media/share"	
	ssh dev@$p "echo 'storage:/plataforma   /media/share  nfs	defaults	0	0' | sudo tee -a /etc/fstab"
	ssh dev@$p "sed '/192.168.1.8/d' /etc/fstab | sudo tee /etc/fstab"
	#ssh dev@$p "echo '//192.168.1.8/plataforma   /media/share  cifs    guest,rw,noforceuid,noforcegid,file_mode=0777,dir_mode=0777,noperm        0       0' | sudo tee -a /etc/fstab"
	ssh dev@$p "sudo umount /media/share"
	ssh dev@$p "sudo systemctl daemon-reload"
	ssh dev@$p "sudo mount -a"
	echo "<< $p - Done!"
done
echo "Done!"
