#!/bin/bash

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
   su -s /bin/bash -c '/var/www/html/occ app:install user_oidc' www-data
   su -s /bin/bash -c '/var/www/html/occ user_oidc:provider autlelia --clientid=nextcloud  --clientsecret='"$SECRET"' --endsessionendpointuri=https://nc.nas.local/ --scope="openid email profile groups" --discoveryuri=https://authelia.nas.local/.well-known/openid-configuration --unique-uid=0 --group-provisioning=1 --mapping-uid=email' www-data
   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=0 user_oidc allow_multiple_user_backends' www-data

   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=yes files_antivirus enabled' www-data
   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=daemon files_antivirus av_mode' www-data
   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=-1 files_antivirus av_stream_max_length' www-data
   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=app-clamav-service files_antivirus av_host' www-data
   su -s /bin/bash -c '/var/www/html/occ config:app:set --value=3310 files_antivirus av_port' www-data
else
  echo "Le fichier /var/www/html/occ n'existe pas."
fi

/entrypoint.sh apache2-foreground