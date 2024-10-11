#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Update"
	# scp get-keys dev@$p:
	# ssh dev@$p "sudo mv get-keys /usr/local/bin && get-keys"
	ssh dev@$p 'get-keys && sudo apt update -y && sudo apt upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y' &
	#ssh dev@$p 'rm ~/.bash_history && rm ~/.zsh_history'
	echo "<< $p"
done
echo "Done!"
