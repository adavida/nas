#!/usr/bin/env bash

mkdir -p secrets
mkdir -p manifest

function gen_secret() {
    FICHIER="$1"
    if [ ! -e "$FICHIER" ]; then
        openssl rand -hex 64 > "$FICHIER"
    fi
}


gen_secret secrets/olcRootPW
slappasswd -s $(cat secrets/olcRootPW) > secrets/olcRootPW.sha
curl  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml > manifest/ingress.yaml 