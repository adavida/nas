{
  config,
  secrets,
  vars,
  ...
}:
{
  services.jellyfin = {
    enable = true;
  };

  services.nginx.virtualHosts."jellyfin.${vars.base_host}" = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
}
