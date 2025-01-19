{ config, pkgs, ... }:
  let 
    path="/var/lib/openldap/data";
    vars = import ./vars.nix;
  in
{
  networking.firewall.allowedTCPPorts = [
      389
      636
  ];
  
  services.openldap = {
    enable = true;
    # mutableConfig = true;

    urlList = [ "ldap:///" "ldapi:///" ];


    settings = {
      attrs = {
        olcLogLevel = "conns config";
      };

      children = {
        "cn=schema".includes = [
          "${pkgs.openldap}/etc/schema/core.ldif"
          "${pkgs.openldap}/etc/schema/cosine.ldif"
          "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
          "${pkgs.openldap}/etc/schema/nis.ldif"
        ];

        "olcDatabase={1}mdb".attrs = {
          objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];

          olcDatabase = "{1}mdb";
          olcDbDirectory = path;

          olcSuffix = vars.base_dn;

          /* your admin account, do not use writeText on a production system */
          olcRootDN = "cn=admin,${vars.base_dn}";
          olcRootPW.path = pkgs.writeText "olcRootPW" (builtins.readFile ./secret/olcRootPW);

          olcAccess = [
            /* custom access rules for userPassword attributes */
            ''{0}to attrs=userPassword
                by self write
                by anonymous auth
                by * none''

            /* allow read on anything else */
            ''{1}to *
                by * read''
          ];
        };
      };
    };
  };
}
