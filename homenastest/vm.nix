{
  config,
  pkgs,
  vars,
  outPath,
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
    make BASE_DOMAIN=${vars.base_host}
    tailscale up
  '';
in
{
  environment.systemPackages = [ init-vm ];
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2048;
      cores = 4;
      graphics = false;
      forwardPorts = [
        {
          from = "host";
          host.port = 2221;
          guest.port = 22;
        }
      ];
      sharedDirectories = {
        secret = {
          source = outPath + "";
          target = src;
        };
      };
    };
  };
}
