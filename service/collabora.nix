{
  config,
  vars,
  secrets,
  ...
}:
let
  ncHost = config.services.nextcloud.hostName;
in
{
  services.collabora-online = {
    enable = true;
    port = 9980;
    settings = {
      server_name = "collabora.${vars.base_host}";
      ssl = {
        enable = false;
        termination = true;
      };
      net = {
        # listen = "loopback";
        post_allow.host = [
          ''127\.0\.0\.1''
          "::1"
          "${vars.ip}"
        ];
      };
      storage.wopi = {
        "@allow" = true;
        host = [
          ncHost
          "https://${ncHost}"
        ];
      };
      storage.ssl_verification = true;
    };
    aliasGroups = [
      {
        host = "https://${ncHost}:443";
        aliases = [ "${vars.ip}" ];
      }
    ];
  };

  services.nginx.virtualHosts.${config.services.collabora-online.settings.server_name} = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.collabora-online.port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
      '';
    };
  };
}
