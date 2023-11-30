#!/bin/bash

# Variables
PROXMOX_IP="176.9.10.239"
PROXMOX_USER="nassima-ayadi"
PROXMOX_PASSWORD="Pleading-Gallon6-Hatred-Stagnant-Imperfect-Surger"
NODE_NAME="wcs-cyber-node01"

# Droit d'exécution
chmod +x api.sh

# Installation de jq si nécessaire
install_jq() {
    if ! command -v jq &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v brew &> /dev/null; then
            sudo brew install -y jq
        else
            echo "Erreur: Aucun gestionnaire de paquets pris en charge trouvé. Veuillez installer jq manuellement."
            exit 1
        fi
    fi
}

# Récupération du Token 

curl --silent --insecure --data "username=${PROXMOX_USER}@pam&password=${PROXMOX_PASSWORD}" https://${PROXMOX_IP}:8006/api2/json/access/ticket | jq --raw-output '.data.ticket' | sed 's/^/PVEAuthCookie=/' > cookie

# Variable Token
TOKEN=$(curl --silent --insecure --data "username=${PROXMOX_USER}@pam&password=${PROXMOX_PASSWORD}" \
 https://${PROXMOX_IP}:8006/api2/json/access/ticket \) | jq --raw-output '.data.ticket')

# Vérification 
if [ -z "$TOKEN" ]; then
    echo "Erreur: Impossible d'obtenir le jeton d'accès."
    exit 1
fi

# Réception du CSRF Token
curl --silent --insecure --data "username=${PROXMOX_USER}@pam&password=${PROXMOX_PASSWORD}" \
 https://${PROXMOX_IP}:8006/api2/json/access/ticket \\n| jq --raw-output '.data.CSRFPreventionToken' | sed 's/^/CSRFPreventionToken:/' > csrftoken

# Variable CSRF Token
CSRF_TOKEN=$(curl --silent --insecure --data "username=${PROXMOX_USER}@pam&password=${PROXMOX_PASSWORD}" \
 https://${PROXMOX_IP}:8006/api2/json/access/ticket \
| jq --raw-output '.data.CSRFPreventionToken')

# Vérification 
if [ -z "$CSRF_TOKEN" ]; then
    echo "Erreur: Impossible d'obtenir le jeton CSRF."
    exit 1
fi

# Lister les machines virtuelles

curl  --insecure --cookie "$(<cookie)" https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE_NAME}/qemu

