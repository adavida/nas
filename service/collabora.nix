{
  config,
  vars,
  secrets,
  ...
}:
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
          "nc.${vars.base_host}"
          "https://nc.${vars.base_host}"
        ];
      };
      storage.ssl_verification = false;
    };
    aliasGroups = [
      {
        host = "https://nc.${vars.base_host}:443";
        aliases = [ "${vars.ip}" ];
      }
    ];
  };

  services.nginx.virtualHosts."collabora.${vars.base_host}" = {
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
