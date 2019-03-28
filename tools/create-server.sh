#! /bin/bash

#
# Création du certificat pour le serveur VPN.
#
# (c) 2015 - Guy Turcotte
#

source "$(dirname "$0")/vpn-params.sh"

if [ -e "${ServerKey}" ]; then

  while true; do
    read -p "VPN Server Key already exists. Do you really want to replace it ? [Yn] " yn
    if [ "$yn" = "" ]; then
      $yn="Y"
    fi
    case "$yn" in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi

echo "Creating Server Key (${ServerKey})..."

ipsec pki --gen --size 2048 --outform pem > "${ServerKey}"
chmod 600 "${ServerKey}"

echo "Creating Server Certificate (${ServerCert})..."

ipsec pki --pub --in "${ServerKey}" | ipsec pki --issue --lifetime 3650 --cacert "${CACert}" --cakey "${CAKey}" --dn "${ServerDN}" --san "${vpn_server_dns_name}" --flag serverAuth --flag ikeIntermediate --outform pem > "${ServerCert}"

echo "\n"

ipsec pki --print --in "${ServerCert}"

echo "\nJob completed!"
