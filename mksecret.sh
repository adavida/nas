#!/usr/bin/env bash

mkdir -p secret

function gen_secret() {
    FICHIER="$1"
    if [ ! -e "$FICHIER" ]; then
        openssl rand -hex 64 > "$FICHIER"
    fi
}


gen_secret secret/olcRootPW