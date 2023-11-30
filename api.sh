#!/bin/bash

# Variables
PROXMOX_IP="<adresse_proxmox>"
PROXMOX_USER="<nom_utilisateur_proxmox>"
PROXMOX_PASSWORD="<mot_de_passe_proxmox>"
NODE_NAME="<noeud_proxmox>"

# Installation de jq si nécessaire
install_jq() {
    if ! command -v jq &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            echo "Erreur: Aucun gestionnaire de paquets pris en charge trouvé. Veuillez installer jq manuellement."
            exit 1
        fi
    fi
}

# Récupération du Token 
TOKEN=$(curl --silent --insecure --data "username=${PROXMOX_USER}@pam&password=${PROXMOX_PASSWORD}" \
 https://${PROXMOX_IP}:8006/api2/json/access/ticket | jq --raw-output '.data.ticket')

# Vérification 
if [ -z "$TOKEN" ]; then
    echo "Erreur: Impossible d'obtenir le jeton d'accès."
    exit 1
fi

# Réception du CSRF Token
CSRF_TOKEN=$(curl --silent --insecure --cookie "PVEAuthCookie=${TOKEN}" \
 https://${PROXMOX_IP}:8006/api2/json/access/ticket | jq --raw-output '.data.CSRFPreventionToken')

# Vérification 
if [ -z "$CSRF_TOKEN" ]; then
    echo "Erreur: Impossible d'obtenir le jeton CSRF."
    exit 1
fi

# Lister les machines virtuelles
curl --insecure --cookie "PVEAuthCookie=${TOKEN}" --header "CSRFPreventionToken: ${CSRF_TOKEN}" \
 https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE_NAME}/qemu
