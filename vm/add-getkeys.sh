#!/bin/bash
set -euo pipefail

for p in `cat inventory`; do
	echo ">> $p - Add proxy config"
	
	ssh dev@$p "crontab -l > add-proxy.cron"	
	ssh dev@$p "echo '0 * * * * export http_proxy=http://192.168.1.10:3128' >> add-proxy.cron"	
	ssh dev@$p "echo '0 * * * * export https_proxy=http://192.168.1.10:3128' >> add-proxy.cron"	
	ssh dev@$p "crontab add-proxy.cron"
	ssh dev@$p "rm add-proxy.cron"
		
	echo "<< $p - Done!"
done
echo "Done!"
