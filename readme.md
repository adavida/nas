# homeNAS

Configuration NixOS (flake) d'un NAS domestique : CoreDNS, OpenLDAP, SFTP, Authelia, Nextcloud.

## Tester (VM)

```bash
nix run .          # démarre la VM homenastest
init-vm            # dans la VM : génère les secrets et initialise
```

## Déployer

```bash
sudo nixos-rebuild switch --flake /etc/nixos#homenas
```

## Secrets

```bash
# sur la machine cible (une fois)
bash /etc/nixos/generate-secret.sh

# certificats (CA maison, wildcard, ldap)
cd secrets/ && make BASE_DOMAIN=nas.local
```

Le CA `secrets/certs/homeCA.pem` est installé comme ancre de confiance par la config.

## Nextcloud (occ)

```bash
nextcloud-occ maintenance:repair
nextcloud-occ security:bruteforce:reset
nextcloud-occ upgrade
nextcloud-occ maintenance:mode --off
```


## authelia

```bash
sudo authelia config template --config.experimental.filters=template --config=/etc/authelia_main.yml 
```


## ldap

```bash
## tester le serveur ldaps depuis la VM
ldapsearch -H ldaps://ldap.nas-test.local -x -D "cn=admin,DC=nas-test,DC=local" -b "DC=nas-test,DC=local" -w $(cat /etc/nixos/secrets/olcRootPW)
```

## PDQL
sudo -u postgres psql -c "ALTER USER nextcloud WITH PASSWORD '$(sudo cat /etc/nixos/secrets/nextcloud/dbpass)';"
PGPASSWORD=$(sudo cat /etc/nixos/secrets/nextcloud/dbpass) psql -h 127.0.0.1 -U nextcloud -d nextcloud -c "\dt"