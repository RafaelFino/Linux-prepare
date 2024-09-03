#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - mount shares"
	
	ssh dev@$p "sudo mount -a"
		
	echo "<< $p - Done!"
done
echo "Done!"
