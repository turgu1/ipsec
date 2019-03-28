# vpn-params.sh

# Il est important de modifier le parametre suivant pour qu'il pointe sur l'addresse DNS
# du réseau local accessible à partir de l'internet.
#
# S'il devait être modifié, il sera nécssaire de regénérer le certificat du serveur VPN.
# Il sera également nécessaire de mettre à jour la configuration des paramètres d'accès du VPN
# localisée dans les postes distants pour réfléter le changement.

vpn_server_dns_name="toto.duckdns.org"

country="CA"
organisation="Home"

root_name="homeRoot CA"
root_key="caHomeKey"
root_cert="caHomeCert"

server_name="homeVPNServer"
server_key="vpnServerKey"
server_cert="vpnServerCert"

CAKey="/etc/ipsec.d/private/${root_key}.pem"
CACert="/etc/ipsec.d/cacerts/${root_cert}.pem"

ServerKey="/etc/ipsec.d/private/${server_key}.pem"
ServerCert="/etc/ipsec.d/certs/${server_cert}.pem"

CADN="C=${country}, O=${organisation}, CN=${root_name}"
ServerDN="C=${country}, O=${organisation}, CN=${vpn_server_dns_name}"
