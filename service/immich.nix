{
  config,
  path,
  secrets,
  vars,
  ...
}:
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
        buttonText = "Login with Authelia";
        clientId = "immich";
        clientSecret._secret = "${path.secrets}/authelia/oicd_immich_secret";
        enabled = true;
        issuerUrl = "https://authelia.${vars.base_host}/.well-known/openid-configuration";
        roleClaim = "immich_role";
        scope = "openid email profile groups immich_scope";
      };
      passwordLogin.enabled = false;
      server.externalDomain = "https://immich.${vars.base_host}";
    };
  };

  services.nginx.virtualHosts."immich.${vars.base_host}" = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      # proxy_buffering off;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
