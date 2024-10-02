#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Update"
	scp get-keys dev@$p:
	ssh dev@$p "sudo mv get-keys /usr/local/bin && get-keys"
	ssh dev@$p 'sudo apt update -y && sudo apt upgrade -y' &
	#ssh dev@$p 'rm ~/.bash_history && rm ~/.zsh_history'
	echo "<< $p"
done
echo "Done!"
