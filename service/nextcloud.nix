{
  config,
  lib,
  path,
  pkgs,
  secrets,
  vars,
  ...
}:
{
  services.nextcloud = {
    enable = true;
    hostName = "nc.${vars.base_host}";
    package = pkgs.nextcloud34;
    https = true;
    config = {
      adminpassFile = "${path.secrets}/nextcloud/adminpass";
      dbpassFile = "${path.secrets}/nextcloud/dbpass";
      dbtype = "pgsql";
      dbhost = "127.0.0.1";
      dbname = "nextcloud";
      dbuser = "nextcloud";
    };
    database.createLocally = false;
    datadir = "/data/ssd/nc";
    phpOptions = {
      "curl.cainfo" = "${path.secrets}/certs/homeCA.pem";
      "openssl.cafile" = "${path.secrets}/certs/homeCA.pem";
      "opcache.interned_strings_buffer" = 20;
    };
    settings = {
      # Some sane defaults required to satisfy Nextcloud configuration check
      # maintenance_window_start = 1;
      default_phone_region = "FR";
      # log_type = "file";
      log_type = "file";
      loglevel = 1;
      serverid = 0;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        user_oidc
        richdocuments
        ;
      files_antivirus = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/files_antivirus/releases/download/v6.4.0/files_antivirus-v6.4.0.tar.gz";
        hash = "sha256-jSEPw6Jp2x5xUgaRT8iv3GjxiouCH2PS1+4//uqNo/Q=";
        license = "agpl3Only";
      };
      # richdocumentscode (Collabora CODE) not in nixpkgs 26.05 — fetched via AppStore at first boot
    };
    extraAppsEnable = true;
  };
  systemd.services.nextcloud-custom-config = {
    path = [
      config.services.nextcloud.occ
    ];
    script =
      let
        wopi_allowlist = [
          "127.0.0.1"
          "::1"
          "collabora.${vars.base_host}"
          vars.ip
        ];
      in
      ''
        BASE_PATH="/etc/nixos";
        BASE_PATH_SECRETS="$BASE_PATH/secrets"

        nextcloud-occ config:system:set user_oidc use_pkce --value=true --type=boolean
        nextcloud-occ config:app:set user_oidc single_logout --value=1 --type=integer
        nextcloud-occ user_oidc:provider autlelia --clientid=nextcloud  --clientsecret-file=$BASE_PATH_SECRETS/authelia/oicd_nextcloud_secret --endsessionendpointuri=https://nc.'${vars.base_host}'/ --scope="openid email profile groups" --discoveryuri=https://authelia.'${vars.base_host}'/.well-known/openid-configuration --unique-uid=0 --group-provisioning=1 --mapping-uid=email
        nextcloud-occ config:app:set user_oidc allow_multiple_user_backends --value=0 --type=string -n

        nextcloud-occ config:system:set allow_local_remote_servers --value=true --type=boolean


        nextcloud-occ app:enable files_antivirus || true
        nextcloud-occ config:app:set files_antivirus av_mode --value=socket
        nextcloud-occ config:app:set files_antivirus av_host --value="${vars.clamav_socket}"
        nextcloud-occ config:app:set files_antivirus av_stream_max_length --value=-1
        nextcloud-occ config:app:set files_antivirus av_infected_action --value=only_log

        # enforce Authelia OIDC as mandatory login (hide local DB backend)
        nextcloud-occ config:system:set lost_password_link --value=disabled --type=string

        # document editing: Nextcloud Office (richdocuments) with dedicated Collabora Online
        # built-in CODE kept as fallback; prefer standalone collabora.${vars.base_host}
        nextcloud-occ app:enable richdocuments || true
        nextcloud-occ config:app:set richdocuments wopi_url --value "https://collabora.${vars.base_host}/"
        nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
      '';
    after = [
      "nextcloud-setup.service"
      "clamav-daemon.service"
    ];
    wants = [
      "clamav-daemon.service"
      "coolwsd.service"
    ];
    wantedBy = [ "multi-user.target" ];
  };

  # files_antivirus in daemon socket mode needs read access to /run/clamav/clamd.ctl
  users.users.nextcloud.extraGroups = [ "clamav" ];

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
    authentication = lib.mkOverride 10 ''
      #type   database        DBuser         address       auth-method
      local   all             all                          peer
      host    nextcloud       nextcloud      127.0.0.1/32  scram-sha-256 
      host    nextcloud       nextcloud      ::1/128       scram-sha-256 
    '';
    settings.port = 5432;
  };
  systemd.services.nextcloud-db-password = {
    description = "set nextcloud postgres password from secrets file";
    after = [ "postgresql.service" ];
    before = [ "nextcloud-setup.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    path = [ config.services.postgresql.package ];
    script = ''
      DBPASS=$(cat "${path.secrets}/nextcloud/dbpass")
      # ponytail: naive single-quote escaping — ok for hex secrets, use psql variables if charset widens
      ESCAPED=''${DBPASS//\'/\'\'}
      psql -c "ALTER ROLE nextcloud WITH PASSWORD '$ESCAPED'"
    '';
  };
}
