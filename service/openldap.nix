{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
let
  path = "/var/lib/openldap/data";
in
{
  networking.firewall.allowedTCPPorts = [
    636
  ];

  services.openldap = {
    enable = true;
    # mutableConfig = true;

    urlList = [
      "ldapi:///"
      "ldaps:///"
    ];

    settings = {
      attrs = {
        olcLogLevel = "conns config";

        olcTLSCACertificateFile = "${secrets}/certs/homeCA.crt";
        olcTLSCertificateFile = "${secrets}/certs/ldap.${vars.base_host}.crt";
        olcTLSCertificateKeyFile = "${secrets}/certs/ldap.${vars.base_host}.key";
        olcTLSCipherSuite = "HIGH:MEDIUM:+3DES:+RC4:+aNULL";
        olcTLSCRLCheck = "none";
        olcTLSVerifyClient = "never";
        olcTLSProtocolMin = "3.1";
      };

      children = {
        "cn=schema".includes = [
          "${pkgs.openldap}/etc/schema/core.ldif"
          "${pkgs.openldap}/etc/schema/cosine.ldif"
          "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
          "${pkgs.openldap}/etc/schema/nis.ldif"
        ];

        "olcDatabase={1}mdb".attrs = {
          objectClass = [
            "olcDatabaseConfig"
            "olcMdbConfig"
          ];

          olcDatabase = "{1}mdb";
          olcDbDirectory = path;

          olcSuffix = vars.base_dn;

          # your admin account, do not use writeText on a production system
          olcRootDN = "cn=admin,${vars.base_dn}";
          olcRootPW.path = "${secrets}/olcRootPW.sha";

          olcAccess = [
            # custom access rules for userPassword attributes
            ''
              {0}to attrs=userPassword
                              by self write
                              by anonymous auth
                              by * none''

            # allow read on anything else
            ''
              {1}to *
              		            by self read
                              by * none''
          ];
        };
      };
    };
  };
}
