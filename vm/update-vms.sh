#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p"
	# scp get-keys dev@$p:/usr/local/bin
	# ssh dev@$p get-keys
	# ssh dev@$p 'sudo locale-gen pt_BR.UTF-8 && sudo dpkg-reconfigure locales'	
	# ssh dev@$p 'sudo apt update -y && sudo apt upgrade -y && sudo reboot' &
	# ssh dev@$p 'sudo reboot'	
	# ssh dev@$p 'rm ~/.bash_history && rm ~/.zsh_history'
	ssh dev@$p "rm sudo && echo '192.168.1.8 storage' | sudo tee -a /etc/hosts"
	echo "<< $p"
done
echo "Done!"
