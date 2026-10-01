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
      globalRedirect = "portail.${vars.base_host}";
      sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
      sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    };
  };
}
