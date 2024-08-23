#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
        echo ">> $p"

        # scp get-keys dev@$p: &&
        ssh dev@$p 'get-keys'
        ssh dev@$p 'sudo apt update -y && sudo apt upgrade -y' &

        echo "<< $p"
done
echo "Done!"