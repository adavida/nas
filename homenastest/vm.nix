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
    cd /etc/nixos
    bash /src/generate-secret.sh
    cd /etc/nixos/secrets
    make BASE_DOMAIN=${vars.base_host}
    tailscale up
    systemctl restart openldap
    ldapadd -x -w $(cat /etc/nixos/secrets/olcRootPW)  -H ldapi:/// -D "cn=admin,dc=nas-test,dc=local" -f /src/users.ldap
    mkdir -p /data/ssd/nc
    chmod 644 /etc/nixos/secrets/certs/homeCA.crt
    chmod 600 /etc/nixos/secrets/certs/homeCA.key
    mkdir -p /data/ssd/immich
    chown immich:immich /data/ssd/immich
    tailscale ip -4

    #halt -p
  '';
  h = pkgs.writeShellScriptBin "h" "sudo halt -p";
  r = pkgs.writeShellScriptBin "h" "sudo reboot";
in
{
  environment.systemPackages = [
    init-vm
    h
    r
    pkgs.authelia
    pkgs.yq
    pkgs.jq
    pkgs.tailspin
  ];
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 16384;
      cores = 8;
      graphics = false;
      forwardPorts = [ ];
      diskSize = 30480;
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
