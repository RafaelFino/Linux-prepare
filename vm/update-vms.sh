#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
        echo ">> $p"

        ssh dev@$p 'get-keys'
		ssh dev@$p 'sudo apt update -y && sudo apt upgrade -y && sudo reboot' &

        echo "<< $p"
done
echo "Done!"
