#!/usr/bin/env bash
set -euo pipefail

# ponytail: 1 fichier pour user/group/member — ldapi + slappasswd, idempotent

usage() {
  cat <<'EOF'
Usage: ldap-manage.sh <command> [args]
Commands:
  user create <cn> [--mail <mail>] [--sn <sn>] [--uidNumber <n>] [--password <pw>]
  user delete <cn>
  user list
  user groups <cn>          # groupes d'un utilisateur
  user passwd <cn> [--password <pw>]  # changer mot de passe
  group create <cn>
  group delete <cn>
  group list
  group members <cn>        # membres d'un groupe
  member add <user-cn> <group-cn>
  member remove <user-cn> <group-cn>
Env: BASE_DN (exporté via common.nix: environment.variables.BASE_DN)
EOF
  exit 1
}

get_pw() { cat /etc/nixos/secrets/olcRootPW; }

user_exists() {
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "cn=${1},ou=users,${BASE_DN}" -s base dn 2>/dev/null | grep -qi "dn:"
}

group_exists() {
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "cn=${1},ou=groups,${BASE_DN}" -s base dn 2>/dev/null | grep -qi "dn:"
}

is_member() {
  # $1=user_dn $2=group_dn
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "$2" member 2>/dev/null | grep -q "$1"
}

next_uid() {
  local max
  max=$(ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "ou=users,${BASE_DN}" uidNumber 2>/dev/null | grep uidNumber | awk '{print $2}' | sort -n | tail -1)
  if [[ -z "$max" ]]; then echo 1100; else echo $((max + 1)); fi
}

user_create() {
  local CN="${1:-}"; shift || true
  [[ -z "$CN" ]] && usage
  local MAIL="" SN="" UIDNUM="" PASS=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mail) MAIL="$2"; shift 2 ;;
      --sn) SN="$2"; shift 2 ;;
      --uidNumber) UIDNUM="$2"; shift 2 ;;
      --password) PASS="$2"; shift 2 ;;
      *) echo "unknown flag $1"; usage ;;
    esac
  done
  if user_exists "$CN"; then echo "user $CN déjà existe ($BASE_DN)"; exit 0; fi
  MAIL="${MAIL:-$CN@mail.com}"
  SN="${SN:-$CN}"
  UIDNUM="${UIDNUM:-$(next_uid)}"
  PASS="${PASS:-$(openssl rand -base64 12)}"
  local HASH
  HASH=$(slappasswd -s "$PASS")
  echo "création user $CN uidNumber=$UIDNUM ($BASE_DN)"
  ldapadd -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// <<EOF
dn: cn=${CN},ou=users,${BASE_DN}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ${CN}
sn: ${SN}
givenName: ${CN}
uid: ${CN}
mail: ${MAIL}
uidNumber: ${UIDNUM}
gidNumber: 1000
homeDirectory: /home/${CN}
loginShell: /bin/bash
userPassword: ${HASH}
EOF
  echo "user $CN créé (password: $PASS)"
}

user_delete() {
  local CN="${1:-}"; [[ -z "$CN" ]] && usage
  if ! user_exists "$CN"; then echo "user $CN n'existe pas"; exit 0; fi
  local USER_DN="cn=${CN},ou=users,${BASE_DN}"
  echo "suppression $USER_DN et nettoyage groupes"
  local g
  for g in $(ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "ou=groups,${BASE_DN}" dn 2>/dev/null | grep "^dn:" | cut -d' ' -f2); do
    if is_member "$USER_DN" "$g"; then
      ldapmodify -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// <<EOF
dn: $g
changetype: modify
delete: member
member: $USER_DN
EOF
      echo "  retiré de $g"
    fi
  done
  ldapdelete -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// "$USER_DN"
  echo "user $CN supprimé"
}

user_list() {
  echo "utilisateurs ($BASE_DN):"
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "ou=users,${BASE_DN}" cn mail uidNumber 2>/dev/null | grep -E "^dn:|^cn:|^mail:|^uidNumber:" || echo "aucun"
}

user_groups() {
  local CN="${1:-}"; [[ -z "$CN" ]] && usage
  local USER_DN="cn=${CN},ou=users,${BASE_DN}"
  echo "groupes de $CN ($BASE_DN):"
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "ou=groups,${BASE_DN}" "member=$USER_DN" cn 2>/dev/null | grep -E "^dn:|^cn:" || echo "aucun"
}

user_passwd() {
  local CN="${1:-}"; shift || true
  [[ -z "$CN" ]] && usage
  local PASS=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --password) PASS="$2"; shift 2 ;;
      *) echo "unknown flag $1"; usage ;;
    esac
  done
  if ! user_exists "$CN"; then echo "user $CN n'existe pas"; exit 1; fi
  PASS="${PASS:-$(openssl rand -base64 12)}"
  # ponytail: ldappasswd gère le hash côté serveur, pas besoin de slappasswd
  echo "changement mot de passe $CN ($BASE_DN)"
  ldappasswd -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// -s "$PASS" "cn=${CN},ou=users,${BASE_DN}"
  echo "mot de passe changé pour $CN (nouveau: $PASS)"
}

group_create() {
  local CN="${1:-}"; [[ -z "$CN" ]] && usage
  if group_exists "$CN"; then echo "group $CN déjà existe"; exit 0; fi
  local MEMBER="cn=user,ou=users,${BASE_DN}"
  if ! ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "$MEMBER" -s base dn 2>/dev/null | grep -qi "dn:"; then
    MEMBER="cn=admin,${BASE_DN}"
  fi
  ldapadd -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// <<EOF
dn: cn=${CN},ou=groups,${BASE_DN}
objectClass: groupOfNames
cn: ${CN}
member: ${MEMBER}
EOF
  echo "group $CN créé (member initial: $MEMBER)"
}

group_delete() {
  local CN="${1:-}"; [[ -z "$CN" ]] && usage
  if ! group_exists "$CN"; then echo "group $CN n'existe pas"; exit 0; fi
  ldapdelete -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// "cn=${CN},ou=groups,${BASE_DN}"
  echo "group $CN supprimé"
}

group_list() {
  echo "groupes ($BASE_DN):"
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "ou=groups,${BASE_DN}" cn member 2>/dev/null | grep -E "^dn:|^cn:|^member:" || echo "aucun"
}

group_members() {
  local CN="${1:-}"; [[ -z "$CN" ]] && usage
  echo "membres de $CN ($BASE_DN):"
  ldapsearch -H ldapi:/// -x -D "cn=admin,${BASE_DN}" -w "$PW" -b "cn=${CN},ou=groups,${BASE_DN}" member 2>/dev/null | grep "^member:" | cut -d' ' -f2- || echo "aucun"
}

member_add() {
  local UCN="${1:-}"; local GCN="${2:-}"; [[ -z "$UCN" || -z "$GCN" ]] && usage
  local USER_DN="cn=${UCN},ou=users,${BASE_DN}"
  local GROUP_DN="cn=${GCN},ou=groups,${BASE_DN}"
  if is_member "$USER_DN" "$GROUP_DN"; then echo "déjà membre"; exit 0; fi
  ldapmodify -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// <<EOF
dn: $GROUP_DN
changetype: modify
add: member
member: $USER_DN
EOF
  echo "ajouté $UCN → $GCN ($BASE_DN)"
}

member_remove() {
  local UCN="${1:-}"; local GCN="${2:-}"; [[ -z "$UCN" || -z "$GCN" ]] && usage
  local USER_DN="cn=${UCN},ou=users,${BASE_DN}"
  local GROUP_DN="cn=${GCN},ou=groups,${BASE_DN}"
  if ! is_member "$USER_DN" "$GROUP_DN"; then echo "pas membre"; exit 0; fi
  ldapmodify -x -D "cn=admin,${BASE_DN}" -w "$PW" -H ldapi:/// <<EOF
dn: $GROUP_DN
changetype: modify
delete: member
member: $USER_DN
EOF
  echo "retiré $UCN de $GCN"
}

CMD="${1:-}"; shift || true
SUB="${1:-}"; shift || true
[[ -z "$CMD" || -z "$SUB" ]] && usage

if [[ -z "${BASE_DN:-}" ]]; then echo "BASE_DN manquant (export BASE_DN ou nixos-rebuild)"; exit 1; fi
PW=$(get_pw)

case "$CMD" in
  user)
    case "$SUB" in
      create) user_create "$@" ;;
      delete) user_delete "$@" ;;
      list) user_list "$@" ;;
      groups) user_groups "$@" ;;
      passwd|password) user_passwd "$@" ;;
      *) usage ;;
    esac
    ;;
  group)
    case "$SUB" in
      create) group_create "$@" ;;
      delete) group_delete "$@" ;;
      list) group_list "$@" ;;
      members) group_members "$@" ;;
      *) usage ;;
    esac
    ;;
  member)
    case "$SUB" in
      add) member_add "$@" ;;
      remove) member_remove "$@" ;;
      *) usage ;;
    esac
    ;;
  *) usage ;;
esac
