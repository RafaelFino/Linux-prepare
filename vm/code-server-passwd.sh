#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - change pass from code server"

	ssh dev@$p "sed -i '/password:/d' ~/.config/code-server/config.yaml" 
	ssh dev@$p "echo password: $p$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4; echo) >> ~/.config/code-server/config.yaml"
	ssh dev@$p "sudo systemctl restart code-server.service"
		
	echo "<< $p - Done!"
done
echo "Done!"
