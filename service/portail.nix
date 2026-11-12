{
  config,
  inputs,
  secrets,
  vars,
  ...
}:
let
  portailHost = "portail.${vars.base_host}";
  portailUrl = "https://${portailHost}";
in
{
  services.portail = {
    enable = true;
    package = inputs.portail.packages.x86_64-linux.portail-backend;
    ldap = {
      adminPasswordFile = "${secrets}/olcRootPW";
      baseDn = vars.base_dn;
      caCertificateFile = "${secrets}/certs/ldap.${vars.base_host}.crt";
      peopleOu = "users";
      url = "ldaps://ldap.${vars.base_host}";
    };
    vhost = {
      forceSSL = true;
      hostName = portailHost;
      sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
      sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    };
    appUrl = portailUrl;
    directory.backend = "ldap"; 
    oidc = {
      logSecretEvents = true;
      secretsDir = "/var/lib/portail/oidc";
    };
    lang = "fr";
  };
}
