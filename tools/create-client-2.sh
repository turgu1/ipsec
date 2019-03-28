#! /bin/bash

#
# Création du certificat pour un poste distant.
#
# Version modifiée pour une clé privée d'autorité de certification (CA) localisée
# sur une barette USB
#
# (c) 2015 - Guy Turcotte
#

#
# Mofifier la ligne suivante pour signifier l'emplacement de la clé privé du CA:
#

CA_Key_Location="/media/usb/"

source "$(dirname "$0")/vpn-params.sh"
 
if [ ! -e "${CA_Key_Location}/${root_key}.pem" ]; then
  echo "Not able to find CA Private Key. Please modify this script to"
  echo "identify the location of the key (CA_Key_Location parameter)"
  echo "and try again."
  exit
fi

while true; do
  read -p "Client Name ? [e.g. Joe Bloe] " client_name
  if [ "${client_name}" = "" ]; then
    echo "Please enter a Client Name."
  else
    break
  fi
done

while true; do
  read -p "Client Key Id ? [e.g. JoeBloe] " client_key
  if [ "${client_key}" = "" ]; then
    echo "Please enter valid Client Key Id (a name without spaces)."
  else
    break
  fi
done

if [ -e "/etc/ipsec.d/private/${client_key}Key.pem" ]; then

  while true; do
    read -p "Client Key already exists. Do you really want to replace it ? [Yn] " yn
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

echo "Creating Client Key (/etc/ipsec.d/private/${client_key}Key.pem)..."

ipsec pki --gen --type rsa --size 2048 --outform pem > "/etc/ipsec.d/private/${client_key}Key.pem"
chmod 600 "/etc/ipsec.d/private/${client_key}Key.pem"

echo "Creating Client Certificate (/etc/ipsec.d/certs/${client_key}Cert.pem)..."

ipsec pki --pub --in "/etc/ipsec.d/private/${client_key}Key.pem" --type rsa | ipsec pki --issue --lifetime 3650 --cacert "/etc/ipsec.d/cacerts/${root_cert}.pem" --cakey "${CA_Key_Location}/${root_key}.pem" --dn "C=${country}, O=${organisation}, CN=${client_name}" --san "${client_name}" --outform pem > "/etc/ipsec.d/certs/${client_key}Cert.pem"

echo "Creating client key/certificate package (/root/${client_key}.p12)..."
echo "Please supply the password to allow access to the certificate package when requested below."

openssl pkcs12 -export -inkey "/etc/ipsec.d/private/${client_key}Key.pem" -in "/etc/ipsec.d/certs/${client_key}Cert.pem" -name "${client_name}" -certfile "/etc/ipsec.d/cacerts/${root_cert}.pem" -caname "${root_name}" -out "/root/${client_key}.p12"

echo "\n"

ipsec pki --print --in "/etc/ipsec.d/certs/${client_key}Cert.pem"

. "$(dirname "$0")/gen-profile.sh" "$client_key"

echo "\nJob completed!"
