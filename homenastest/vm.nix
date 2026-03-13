{
  config,
  pkgs,
  vars,
  outPath,
  lib,
  ...
}:
let
  src = "/src";
  init-vm = pkgs.writeShellScriptBin "init-vm" ''
    mkdir /etc/nixos/secrets
    mkdir /sftp
    cp ${src}/secrets/makefile /etc/nixos/secrets
    cp ${src}/mksecret.sh      /etc/nixos
    cd /etc/nixos
    bash mksecret.sh
    cd /etc/nixos/secrets
    systemctl restart k3s.service
    make BASE_DOMAIN=${vars.base_host}
    make BASE_DOMAIN=${vars.base_host} k8s
    tailscale up
    ldapadd -x -w $(cat /etc/nixos/secrets/olcRootPW)  -H ldapi:/// -D "cn=admin,dc=nas-test,dc=local" -f /src/users.ldap
  '';
in
{
  environment.systemPackages = [ init-vm ];
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8196;
      cores = 4;
      graphics = false;
      forwardPorts = [ ];
      diskSize = 20480;
      # diskSizeAutoSupported = lib.mkDefault true;
      sharedDirectories = {
        src = {
          source = outPath + "";
          target = src;
        };
      };
    };
  };
}
