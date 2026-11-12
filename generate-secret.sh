#!/bin/bash

generate_random_string() {
    local n=$1
    # openssl rand -hex $n
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$n"
}

function gen_secret() {
    FICHIER="$1"
    if [ ! -e "$FICHIER" ]; then
        openssl rand -hex 64 > "$FICHIER"
    fi
}

generate_file_if_no_exit() {
    if [ ! -e $1 ]; then
        touch "$1"
        echo éditer $1
    fi
}

ENV="${1:-test}"

case "$ENV" in
    prod)
        CN="nas.local"
        ;;
    test)
        CN="nas-test.local"
        ;;
    *)
        echo "Usage: $0 [test|prod]"
        exit 1
        ;;
esac


BASE_PATH="/etc/nixos";
echo "environnement: ${ENV}"
echo "base path : ${BASE_PATH}"
echo "cn : ${CN}"

BASE_PATH_SECRETS="${BASE_PATH}/secrets"
BASE_PATH_KEY="${BASE_PATH}/key"


gen_secret "$BASE_PATH_SECRETS/olcRootPW"
slappasswd -s $(cat "$BASE_PATH_SECRETS/olcRootPW") > "$BASE_PATH_SECRETS/olcRootPW.sha"

gen_secret "$BASE_PATH_SECRETS/nextcloud/adminpass"
gen_secret "$BASE_PATH_SECRETS/nextcloud/dbpass"

gen_secret "$BASE_PATH_SECRETS/photoprism/adminpass"
# ponytail: EnvironmentFile for photoprism — single KEY=VAL file read by systemd
if [ ! -e "$BASE_PATH_SECRETS/photoprism/env" ]; then
  # reuse shared OIDC secret (same file as Authelia) for single source of truth
  echo "PHOTOPRISM_OIDC_SECRET=$(cat "$BASE_PATH_SECRETS/authelia/oicd_photoprism_secret")" > "$BASE_PATH_SECRETS/photoprism/env"
  chmod 0400 "$BASE_PATH_SECRETS/photoprism/env"
fi
