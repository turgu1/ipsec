#!/bin/bash

#
# A la fin de la ligne POSTROUTING, assurez-vous de modifier l'adresse pour celle
# du serveur vpn.
#

iptables -F

# ---- Policies ----

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# ---- Inputs ----

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Modifier la ligne suivante pour indiquer l'adresse du serveur VPN
iptables -t nat -A POSTROUTING -o eth0 ! -p esp -j SNAT --to-source 192.168.1.208
iptables -A INPUT -p udp --dport 500 --j ACCEPT
iptables -A INPUT -p udp --dport 4500 --j ACCEPT
iptables -A INPUT -p tcp --dport 22 --j ACCEPT
iptables -A INPUT -p esp -j ACCEPT

# bonjour
iptables -A INPUT -p udp --dport 5353 --j ACCEPT
iptables -A INPUT -p udp --dport 5350 --j ACCEPT
iptables -A INPUT -p udp --dport 5351 --j ACCEPT
iptables -A INPUT -p udp --dport 1900 --j ACCEPT

# Log and drop everything else
iptables -A INPUT -j LOG --log-prefix "iptables_input "
iptables -A INPUT -j DROP

# ---- Outputs ----

iptables -A OUTPUT -o lo -d 127.0.0.0/8 -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ssh
iptables -A OUTPUT -p tcp -m multiport --dport 22 -j ACCEPT

# dns
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# http (nécessaire pour l'usage de apt-get)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# ntp 
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# bonjour
iptables -A OUTPUT -p udp --dport 5353 -j ACCEPT
iptables -A OUTPUT -p udp --dport 5350 -j ACCEPT
iptables -A OUTPUT -p udp --dport 5351 -j ACCEPT
iptables -A OUTPUT -p udp --dport 1900 -j ACCEPT

# indigo --- X10, etc...
iptables -A OUTPUT -p tcp --dport 8176 -j ACCEPT

# DHCP
iptables -A OUTPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT

# Log and drop everything else
iptables -A OUTPUT -j LOG --log-prefix "iptables_output "
iptables -A OUTPUT -j DROP

# ---- Creation des fichiers de configuration ----

iptables-save >/root/firewall.rules
cp /root/firewall.rules /etc/iptables.up.rules

cat > /etc/network/if-pre-up.d/iptables << EOL
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.up.rules
EOL

chmod 0755 /etc/network/if-pre-up.d/iptables
