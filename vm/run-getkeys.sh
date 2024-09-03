#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Update get-keys"
	
	scp get-keys dev@$p:
	ssh dev@$p "sudo mv get-keys /usr/local/bin"
	ssh dev@$p "get-keys"
		
	echo "<< $p - Done!"
done
echo "Done!"
