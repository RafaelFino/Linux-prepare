#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Install code server"
	
	# ssh dev@$p "export http_proxy='http://proxy:3128' && export https_proxy='http://proxy:3128' && curl -fsSL https://code-server.dev/install.sh | sh"

	#ssh dev@$p "mkdir ~/.config/code-server"
	#ssh dev@$p "touch ~/.config/code-server/config.yaml"

	#ssh dev@$p "echo bind-addr: $(dig +short $p):8079 > ~/.config/code-server/config.yaml"
	#ssh dev@$p "echo auth: password >> ~/.config/code-server/config.yaml"
	#ssh dev@$p "echo password: vscode-na-vm  >> ~/.config/code-server/config.yaml"
	#ssh dev@$p "echo cert: false  >> ~/.config/code-server/config.yaml"

	#scp code-server.service dev@$p:
	#ssh dev@$p "sudo mv /home/dev/code-server.service /usr/local/bin"
	#ssh dev@$p "sudo ln -sf /usr/local/bin/code-server.service /etc/systemd/system"

	ssh dev@$p "sudo systemctl enable code-server.service"
	ssh dev@$p "sudo systemctl start code-server.service"
		
	echo "<< $p - Done!"
done
echo "Done!"
