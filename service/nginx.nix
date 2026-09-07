{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."${vars.base_host}" = {
      forceSSL = true;
      sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
      sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
      locations."/" = {
        return = "200 '<html><body>It works</body></html>'";
        extraConfig = ''
          default_type text/html;
        '';
      };
    };
  };
}
