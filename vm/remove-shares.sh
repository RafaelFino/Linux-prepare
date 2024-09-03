#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Removing shares"
	ssh dev@$p "sudo umount //192.168.1.8/share-b"
	ssh dev@$p "sudo umount //192.168.1.8/share-c"
	ssh dev@$p "sudo rm -rf /media/share-b"	
	ssh dev@$p "sudo rm -rf /media/share-c"	
	ssh dev@$p "sed '/share-b/d' /etc/fstab | sudo tee /etc/fstab"
	ssh dev@$p "sed '/share-c/d' /etc/fstab | sudo tee /etc/fstab"
	ssh dev@$p "sudo systemctl daemon-reload"
	echo "<< $p - Done!"
done
echo "Done!"
