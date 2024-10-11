#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Reset"
	ssh dev@$p "sudo reboot"
	echo "<< $p"
done
echo "Done!"
