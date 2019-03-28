#! /bin/bash

#
# Création du certificat pour un poste distant.
#
# (c) 2015 - Guy Turcotte
#

source "$(dirname "$0")/vpn-params.sh"

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

ClientKey="/etc/ipsec.d/private/${client_key}Key.pem"
ClientCert="/etc/ipsec.d/certs/${client_key}Cert.pem"
ClientP12="/root/${client_key}.p12"
ClientDN="C=${country}, O=${organisation}, CN=${client_name}"

echo "Creating Client Key (${ClientKey})..."

ipsec pki --gen --size 2048 --outform pem > "${ClientKey}"
chmod 600 "${ClientKey}"

echo "Creating Client Certificate (${ClientCert})..."

ipsec pki --pub --in "${ClientKey}" | ipsec pki --issue --lifetime 3650 --cacert "${CACert}" --cakey "${CAKey}" --dn "${ClientDN}" --san "${client_name}" --outform pem > "${ClientCert}"

echo "Creating client key/certificate package (/root/${client_key}.p12)..."
echo "Please supply the password to allow access to the certificate package when requested below."

openssl pkcs12 -export -inkey "${ClientKey}" -in "${ClientCert}" -name "${client_name}" -certfile "${CACert}" -caname "${root_name}" -out "${ClientP12}"

echo ""

ipsec pki --print --in "${ClientCert}"

. "$(dirname "$0")/gen-profile-client.sh" "${client_key}"

echo ""
echo "Job completed!"
