#! /bin/bash

#
# Revocation d'un certificat de poste distant
#
#
# (c) 2015 - Guy Turcotte
#

source "$(dirname "$0")/vpn-params.sh"

while true; do
  read -p "Client Key Id ? [e.g. JoeBloe] " client_key
  if [ "${client_key}" = "" ]; then
    echo "Please enter valid Client Key Id (a name without spaces)."
  else
    break
  fi
done

while true; do
  read -p "Revoking Key ${client_key}. Are you sure ? [yN] " yn
  if [ "$yn" = "" ]; then
    $yn="N"
  fi
  case "$yn" in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

echo "Revoking Key ${client_key}..."

if [ -e "/etc/ipsec.d/crls/crl.pem" ]; then
  cp /etc/ipsec.d/crls/crl.pem /tmp/crl.pem.tmp
  cmd1="--lastcrl /tmp/crl.pem.tmp"
  cmd2="rm /tmp/crl.pem.tmp"
else
  cmd1=""
  cmd2=""
fi

ipsec pki --signcrl --reason key-compromise --cacert /etc/ipsec.d/cacerts/${root_cert}.pem --cakey /etc/ipsec.d/private/${root_key}.pem --cert /etc/ipsec.d/certs/${client_key}Cert.pem $cmd1 --outform pem > /etc/ipsec.d/crls/crl.pem

$cmd2

echo "Job Completed!"
