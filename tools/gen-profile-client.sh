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

ClientId="$1"
XAuthName="$2"

CaCertFileName="${root_cert}.pem"
#CaCertLocation="$(dirname "$0")/../${CaCertFileName}"
CaCertLocation=/etc/ipsec.d/cacerts/${CaCertFileName}

level=1  # Indentation Level

if [ "${ClientId}" = "" ]; then
  while true; do
    read -p "Client Key Id ? [e.g. JoeBloe] " ClientId
    if [ "${ClientId}" = "" ]; then
      echo "Please enter valid Client Key Id (a name without spaces)."
    else
      break
    fi
  done
fi

if [ "${XAuthName}" = "" ]; then
  while true; do
    read -p "XAuth User Id ? [e.g. joebloe1] " XAuthName
    if [ "${XAuthName}" = "" ]; then
      echo "Please enter valid XAuth User Id (a name without spaces)."
    else
      break
    fi
  done
fi

#file="$(dirname "$0")/../${ClientId}.mobileconfig"
file="/root/${ClientId}.mobileconfig"

UserCertFileName="${ClientId}.p12"
#UserCertLocation="$(dirname "$0")/../${UserCertFileName}"
UserCertLocation="/root/${UserCertFileName}"

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

put_str  PayloadIdentifier          com.apple.mdm
put_bool PayloadRemovalDisallowed   false
put_str  PayloadScope               User
put_str  PayloadType                Configuration
put_str  PayloadUUID                "`uuidgen | tr [a-z] [A-Z]`"
put_str  PayloadOrganization        "${organisation}"
put_int  PayloadVersion             1
put_str  PayloadDisplayName         "${organisation} VPN Settings"
put_tag  key PayloadContent

put_start array

# ----- User Certificate -----

CertUUID="`uuidgen | tr [a-z] [A-Z]`"

put_start dict
put_str  PayloadType                com.apple.security.pkcs12
put_str  PayloadIdentifier          com.apple.mdm.certificate
put_str  PayloadUUID                "${CertUUID}"
put_str  PayloadCertificateFileName "${UserCertFileName}"
put_int  PayloadVersion             1
put_str  PayloadDisplayName         "${ClientId} Certificate"
put_tag  key PayloadContent
put_start data
${b64} "${UserCertLocation}" | sed -e "s/^/`printf "%*s" $((level*2))`/" >>"${file}"
put_end   data
put_end dict

# ----- VPN Instance -----

put_start dict
put_str  PayloadType                com.apple.vpn.managed
put_str  PayloadIdentifier          com.apple.mdm.vpn
put_str  PayloadUUID                "`uuidgen | tr [a-z] [A-Z]`"
put_int  PayloadVersion             1
put_bool PayloadEnabled             true
put_str  PayloadDisplayName         "${organisation} VPN"
put_str  VPNType                    IPSec
put_tag  key IPSec

put_start dict
put_str  RemoteAddress              "${vpn_server_dns_name}"
put_str  AuthenticationMethod       Certificate
put_int  XAuthEnabled               1
put_str  XAuthName                  "${XAuthName}"
put_str  PayloadCertificateUUID     "${CertUUID}"
put_int  OnDemandEnabled            0
put_end   dict

put_str  UserDefinedName            "${organisation} VPN"
put_tag  key IPv4
put_start dict
put_int  OverridePrimary            1
put_end  dict

put_end dict

put_end array

put_end dict

echo "</plist>" >>"${file}"
