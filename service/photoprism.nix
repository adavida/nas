{
  config,
  path,
  secrets,
  vars,
  ...
}:
{
  services.photoprism = {
    address = "127.0.0.1";
    enable = true;
    importPath = "${vars.photoprism_originals_path}/import";
    originalsPath = vars.photoprism_originals_path;
    passwordFile = "${path.secrets}/photoprism/adminpass";
    port = 2342;
    settings = {
      PHOTOPRISM_ADMIN_USER = "admin";
      PHOTOPRISM_DEBUG = "true";
      PHOTOPRISM_DEFAULT_LOCALE = "fr";
      PHOTOPRISM_LOG_LEVEL = "trace";
      PHOTOPRISM_OIDC_CLIENT = "photoprism";
      PHOTOPRISM_OIDC_PROVIDER = "authelia";
      PHOTOPRISM_OIDC_REDIRECT = "true";
      PHOTOPRISM_OIDC_REGISTER = "true";
      PHOTOPRISM_OIDC_URI = "https://authelia.${vars.base_host}";
      PHOTOPRISM_SITE_CAPTION = "Browse Your Life";
      PHOTOPRISM_SITE_URL = "https://photoprism.${vars.base_host}/";
      PHOTOPRISM_TRACE = "true";
    };
  };

  systemd.services.photoprism.serviceConfig.EnvironmentFile = "${path.secrets}/photoprism/env";

  services.nginx.virtualHosts."photoprism.${vars.base_host}" = {
    forceSSL = true;
    locations."/" = {
      extraConfig = ''
        client_max_body_size 50000M;
      '';
      proxyPass = "http://127.0.0.1:2342";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
  };
}
