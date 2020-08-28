sudo iptables -P FORWARD ACCEPT
sudo sysctl -w net.ipv4.ip_forward=1
	
	
sudo iptables-save -t nat | grep -oP '(?<!^:)cali-[^ ]+' | while read line; do sudo iptables -t nat -F $line; done
sudo iptables-save -t raw | grep -oP '(?<!^:)cali-[^ ]+' | while read line; do sudo iptables -t raw -F $line; done
sudo iptables-save -t mangle | grep -oP '(?<!^:)cali-[^ ]+' | while read line; do sudo iptables -t mangle -F $line; done
sudo iptables-save -t filter | grep -oP '(?<!^:)cali-[^ ]+' | while read line; do sudo iptables -t filter -F $line; done
sudo iptables-save -t nat | grep -e '--comment "cali:' | cut -c 3- | sed 's/^ *//;s/ *$//' | xargs -l1 sudo iptables -t nat -D
sudo iptables-save -t filter | grep -e '--comment "cali:' | cut -c 3- | sed 's/^ *//;s/ *$//' | xargs -l1 sudo iptables -t filter -D
sudo iptables-save -t mangle | grep -e '--comment "cali:' | cut -c 3- | sed 's/^ *//;s/ *$//' | xargs -l1 sudo iptables -t mangle -D
sudo iptables-save -t raw | grep -e '--comment "cali:' | cut -c 3- | sed 's/^ *//;s/ *$//' | xargs -l1 sudo iptables -t raw -D
