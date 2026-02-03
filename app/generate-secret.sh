#!/bin/bash

generate_random_string() {
    local n=$1
    # openssl rand -hex $n
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$n"
}

generate_file_if_no_exit() {
    if [ ! -e $1 ]; then
        touch "$1"
        echo éditer $1
    fi
}



# BASE_PATH="$(dirname "$0")/secrets/test"
# CN="nas-test.local"
BASE_PATH="$(dirname "$0")/secrets/prod"
CN="nas.local"

echo "base path : ${BASE_PATH}"
echo "cn : ${CN}"

BASE_PATH_SECRETS="${BASE_PATH}/secrets"
BASE_PATH_KEY="${BASE_PATH}/key"

mkdir -p "$BASE_PATH_SECRETS/authelia"
mkdir -p "$BASE_PATH_KEY/authelia"

generate_random_string  64 > "$BASE_PATH_SECRETS/authelia/jwt_secret"
generate_random_string  64 > "$BASE_PATH_SECRETS/authelia/session_secret"
generate_random_string  64 > "$BASE_PATH_SECRETS/authelia/oidc_hmac_secret"
generate_random_string  64 > "$BASE_PATH_SECRETS/authelia/oicd_nextcloud_secret"
generate_random_string  64 > "$BASE_PATH_SECRETS/authelia/storage_encryption_key"

ssh root@ssh."${CN}" -C 'cat /etc/nixos/secrets/olcRootPW'  > "$BASE_PATH_SECRETS/authelia/ldap_password"

openssl req -x509 -nodes -newkey rsa:2048 -keyout "$BASE_PATH_KEY/authelia/private.pem" -out "$BASE_PATH_KEY/authelia/public.crt" -sha256 -days 365 -subj "/CN=$CN"
openssl genpkey -algorithm RSA -out "$BASE_PATH_KEY/authelia/private_key.pem" -pkeyopt rsa_keygen_bits:2048
openssl req -new -x509 -key "$BASE_PATH_KEY/authelia/private_key.pem" -out "$BASE_PATH_KEY/authelia/certificate.pem" -days 365 -subj "/CN=$CN"
