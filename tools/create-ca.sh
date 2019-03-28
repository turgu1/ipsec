#! /bin/bash

#
# Création du certificat de l'Autorité de certification (root CA)
#
# Attention!!!
# ------------
#
# Une fois créée, la clé privée de l'authorité de certification doit absolument être retirée de tout
# accès potentielle de l'internet car l'ensemble des clés et certificats dépendent de cette clé.
# Une barette usb est un bon endroit pour la conserver...
#
# Il ne faut surtout pas la perdre non plus car il sera impossible de créer d'autres certificats sans
# regénérer l'ensemble des clés et certificats à partir d'une nouvelle clé privée.
#
# (c) 2015 - Guy Turcotte
#

source "$(dirname "$0")/vpn-params.sh"

if [ -e  "${CAKey}" ]; then

  while true; do
    read -p "CA Key already exists. Do you really want to replace it ? [Yn] " yn
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

echo "Creating CA Key (${CAKey})..."

ipsec pki --gen --size 4096 --outform pem > "${CAKey}" 
chmod 600 "${CAKey}"

echo "Creating CA Certificate (${CACert})..."

ipsec pki --self --ca --lifetime 3650 --in "${CAKey}" --dn "${CADN}" --outform pem > "${CACert}"

echo ""

ipsec pki --print --in "${CACert}"

. "$(dirname "$0")/gen-profile-ca.sh"

echo ""
echo "Job completed!"
