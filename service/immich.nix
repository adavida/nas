{
  config,
  path,
  secrets,
  vars,
  ...
}:
let
  immichClientId = "immich";
  immichHost = "immich.${vars.base_host}";
  immichUrl = "https://${immichHost}";
  portailUrl = config.services.portail.appUrl;
in
{
  nixpkgs.config.permittedInsecurePackages = [ "immich-2.7.5" ];

  services.immich = {
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
    enable = true;
    environment = {
      IMMICH_API_METRICS_PORT = "8081";
      IMMICH_MICROSERVICES_METRICS_PORT = "8082";
      IMMICH_TELEMETRY_INCLUDE = "all";
    };
    mediaLocation = "/data/ssd/immich";
    port = 2283;
    settings = {
      oauth = {
        autoLaunch = true;
        autoRegister = true;
        buttonText = "Login with portail";
        clientId = immichClientId;
        clientSecret._secret = "/var/lib/portail/oidc/immich_secret";
        enabled = true;
        issuerUrl = "${portailUrl}/.well-known/openid-configuration";
        roleClaim = "immich_role";
        scope = "openid email profile groups";
      };
      passwordLogin.enabled = false;
      server.externalDomain = immichUrl;
    };
  };

  services.nginx.virtualHosts.${immichHost} = {
    forceSSL = true;
    locations."/" = {
      # proxy_buffering off;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
      proxyPass = "http://localhost:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
  };

  services.portail.apps = [
    {
      description = "Photo";
      icon = "https://raw.githubusercontent.com/immich-app/immich/main/design/immich-logo.png";
      name = "immich";
      oidc = {
        clientId = immichClientId;
        enable = true;
        group = "immich";
        redirectUris = [
          "${immichUrl}/auth/login"
          "${immichUrl}/api/oauth/mobile-redirect"
        ];
        user = "immich";
        customClaims = [
          {
            name = "immich_role";
            value = "user";
          }
          {
            name = "immich_role";
            value = "admin";
            group = "admin";
          }
        ];
      };
      url = immichUrl;
    }
  ];

  systemd.services.immich-server = {
    after = [ "portail-backend.service" ];
    requires = [ "portail-backend.service" ];
    restartIfChanged = true;
  };
}
