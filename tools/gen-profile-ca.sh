#!/bin/bash

#
# Création du profil de configuration pour l'instantiation des certificats et du VPN sous IOS et OSX
#
# Paramètres d'entrée:
#
# $1 - Identifiant de la clé client tel que fourni à create-client.sh ou create-client-2.sh
# $2 - Identifiant XAuth selon la table /etc/ipsec.secrets
#
# (c) 2015 - Guy Turcotte
#

source "$(dirname "$0")/vpn-params.sh"

#b64="base64 -b 64"
b64="base64 -w 64"

CaCertFileName="${root_cert}.pem"
#CaCertLocation="$(dirname "$0")/../${CaCertFileName}"

level=1  # Indentation Level

#file="$(dirname "$0")/../${ClientId}.mobileconfig"
file="/root/${root_cert}.mobileconfig"

put_tag()   { printf "%*s<%s>%s</%s>\n" $((level*2)) " " "$1" "$2" "$1" >>"${file}"; }
put_etag()  { printf "%*s<%s/>\n" $((level*2)) " " "$1" >>"${file}"; }
put_str()   { put_tag "key" "$1"; put_tag "string" "$2"; }
put_int()   { put_tag "key" "$1"; put_tag "integer" "$2"; }
put_bool()  { put_tag "key" "$1"; put_etag $2; }
put_start() { printf "%*s<%s>\n" $((level++*2)) " " "$1" >>"${file}"; }
put_end()   { printf "%*s</%s>\n" $((--level*2)) " " "$1" >>"${file}"; }

cat <<EOF >"$file"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
EOF

put_start dict

put_str  PayloadIdentifier          com.apple.mdm.ca
put_bool PayloadRemovalDisallowed   false
put_str  PayloadScope               System
put_str  PayloadType                Configuration
put_str  PayloadUUID                "`uuidgen | tr [a-z] [A-Z]`"
put_str  PayloadOrganization        "${organisation}"
put_int  PayloadVersion             1
put_str  PayloadDisplayName         "${organisation} CA"
put_tag  key PayloadContent

put_start array

# ----- CA Certificate -----

put_start dict
put_str  PayloadType                com.apple.security.pem
put_str  PayloadIdentifier          com.apple.mdm.ca.cacertificate
put_str  PayloadUUID                "`uuidgen | tr [a-z] [A-Z]`"
put_str  PayloadCertificateFileName "${CaCertFileName}"
put_int  PayloadVersion             1
put_str  PayloadDisplayName         "${organisation} CA Certificate"
put_tag  key PayloadContent
put_start data
${b64} "${CACert}" | sed -e "s/^/`printf "%*s" $((level*2))`/" >>"${file}"
put_end   data
put_end dict

put_end array

put_end dict

echo "</plist>" >>"${file}"
