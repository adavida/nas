{
  config,
  inputs,
  secrets,
  vars,
  ...
}:
{
  services.portail = {
    enable = true;
    package = inputs.portail.packages.x86_64-linux.portail-backend;
    ldap = {
      adminPasswordFile = "${secrets}/olcRootPW";
      baseDn = vars.base_dn;
      url = "ldaps://ldap.${vars.base_host}";
      caCertificateFile = "${secrets}/certs/ldap.${vars.base_host}.crt";
      peopleOu = "users";
    };
    appUrl = "https://portail.${vars.base_host}";
    issuerUrl = "https://authelia.${vars.base_host}";
    oidc.clientSecretFile = "${secrets}/authelia/oicd_portail_secret";
    vhost = {
      hostName = "portail.${vars.base_host}";
      forceSSL = true;
      sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
      sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    };
  };
}
