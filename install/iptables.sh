apt update && apt install ipset iptables-persistent ipset-persistent -y
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

systemctl enable ipset-persistent
systemctl status ipset-persistent
