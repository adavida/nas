{
  config,
  pkgs,
  secrets,
  vars,
  path,
  ...
}:
let
  vars_path = "/var/lib/authelia-main";
  configFile = "/var/lib/authelia-main/config.yml";
  execCommand = "${pkgs.authelia}/bin/authelia";
  configArg = " --config.experimental.filters=template --config=/etc/authelia_main.yml";
  user = "authelia-main";
  group = "authelia-main";
in
{
  environment.etc."authelia_main.yml".text =
    builtins.replaceStrings
      [ "#HOSTNAME#" "#IP#" "#BASEDN#" "#PATHSECRET#" "#PATHKEY#" "#VARSPATH#" ]
      [ vars.base_host vars.ip vars.base_dn path.secrets path.keys vars_path ]
      (builtins.readFile ./authelia/configuration.yaml);

  systemd.services.authelia-main = {
    description = "Authelia authentication and authorization server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ]; # Checks SMTP notifier creds during startup
    wants = [ "network-online.target" ];
    environment = {
      AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "${path.secrets}/authelia/jwt_secret";
      AUTHELIA_SESSION_SECRET_FILE = "${path.secrets}/authelia/session_secret";
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "${path.secrets}/authelia/storage_encryption_key";
      AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "${path.secrets}/authelia/oidc_hmac_secret";
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "${path.secrets}/olcRootPW";
    };

    preStart = "${execCommand} ${configArg} validate-config";
    serviceConfig = {
      User = user;
      Group = group;
      ExecStart = "${execCommand} ${configArg}";
      Restart = "always";
      RestartSec = "5s";
      StateDirectory = "authelia-main";
      StateDirectoryMode = "0700";

      # Security options:
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      DeviceAllow = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;

      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;

      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = "read-only";
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "noaccess";
      ProtectSystem = "strict";

      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;

      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = [
        "@system-service"
        "~@cpu-emulation"
        "~@debug"
        "~@keyring"
        "~@memlock"
        "~@obsolete"
        "~@privileged"
        "~@setuid"
      ];
    };
  };

  users = {
    groups."${group}" = { };
    users."${user}" = {
      isSystemUser = true;
      group = group;
    };
  };

  services.nginx.virtualHosts."authelia.${vars.base_host}" = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      extraConfig = ''
        proxy_set_header X-Original-URL $scheme://$host$request_uri;

        send_timeout 5m;
        proxy_read_timeout 240;
        proxy_send_timeout 240;
        proxy_connect_timeout 240;
      '';
    };
  };
}
