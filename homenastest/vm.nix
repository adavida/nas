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
    mkdir -p /data/ssd/nc
    tailscale ip -4
    halt -p
  '';
  print-k3s = pkgs.writeShellScriptBin "print-k3s" "cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${vars.ip}/g'";
in
{
  environment.systemPackages = [ init-vm print-k3s ];
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
