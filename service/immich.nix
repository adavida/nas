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
    enable = true;
    # host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/data/ssd/immich";
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
    settings = {
      server.externalDomain = "https://immich.${vars.base_host}";
      passwordLogin.enabled = false;
      oauth = {
        enabled = true;
        issuerUrl = "https://authelia.${vars.base_host}/.well-known/openid-configuration";
        clientId = "immich";
        clientSecret._secret = "${path.secrets}/authelia/oicd_immich_secret";
        scope = "openid email profile groups immich_scope";
        buttonText = "Login with Authelia";
        autoRegister = true;
        autoLaunch = true;
        roleClaim = "immich_role";
      };
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
