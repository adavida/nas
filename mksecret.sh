#!/usr/bin/env bash

mkdir -p secret
mkdir -p manifest

function gen_secret() {
    FICHIER="$1"
    if [ ! -e "$FICHIER" ]; then
        openssl rand -hex 64 > "$FICHIER"
    fi
}


gen_secret secret/olcRootPW
curl  https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml > manifest/ingress.yaml 