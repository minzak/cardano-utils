service netfilter-persistent flush

iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m comment --comment "Allow pings" -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -m comment --comment "Allow pings" -j ACCEPT
iptables -A INPUT -p tcp -m comment --comment "Allow SSH" -m state --state NEW -m tcp -m multiport --dports 22,2233 -j ACCEPT
iptables -A INPUT -p tcp -m comment --comment "Allow nginx HTTP & HTTPS" -m state --state NEW -m tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A INPUT -s MYINFRAIP/32 -p tcp -m comment --comment "Allow connect to node_exporter" -m state --state NEW -m tcp --dport 9100 -j ACCEPT
iptables -A INPUT -s MYINFRAIP/32 -p tcp -m comment --comment "Allow connect to Cardano_exporter" -m state --state NEW -m tcp --dport 12798 -j ACCEPT
iptables -A INPUT -p tcp -m comment --comment "Allow connect to Cardano network" -m state --state NEW -m tcp --match multiport --dports 3000:3002 -j ACCEPT

#In order to protect your Relay Node(s) from a novel "DoS/Syn" attack, created iptables entry which restricts connections to a given destination port to 5 connections from the same IP
iptables -I INPUT -p tcp -m tcp --match multiport --dports 3000:3002 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 10 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset

iptables -P INPUT DROP
iptables -P FORWARD DROP
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

service netfilter-persistent save

