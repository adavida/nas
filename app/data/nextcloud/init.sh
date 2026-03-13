#!/bin/bash

function occ {
    su -s /bin/bash -c '/var/www/html/occ '"$*"  www-data
}
  
/usr/sbin/update-ca-certificates --fresh
if [ -e /var/www/html/occ ]; then
  echo "<?php
  \$CONFIG = array (
    'user_oidc' => [
      'use_pkce' => true,
    ],
    'overwriteprotocol' => 'https',
     'allow_local_remote_servers' => true,
  );
" > /var/www/html/config/cluster.config.php

   SECRET=$(cat /secret)
   echo $UID
   occ app:install user_oidc
   occ 'user_oidc:provider autlelia --clientid=nextcloud  --clientsecret='"$SECRET"' --endsessionendpointuri=https://nc.'"${BASE_HOST_NAME}"'/ --scope="openid email profile groups" --discoveryuri=https://authelia.'${BASE_HOST_NAME}'/.well-known/openid-configuration --unique-uid=0 --group-provisioning=1 --mapping-uid=email'
   occ config:app:set --value=0 user_oidc allow_multiple_user_backends

   occ app:update --all

   occ config:app:set --value=yes files_antivirus enabled
   occ config:app:set --value=daemon files_antivirus av_mode
   occ config:app:set --value=-1 files_antivirus av_stream_max_length
   occ config:app:set --value=app-clamav-service files_antivirus av_host
   occ config:app:set --value=3310 files_antivirus av_port 
else
  echo "Le fichier /var/www/html/occ n'existe pas."
fi

/entrypoint.sh apache2-foreground