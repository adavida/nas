# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  vars,
  ...
}:
let
  halt-shell = pkgs.writeShellScriptBin "halt-shell" "exec sudo ${pkgs.systemd}/bin/poweroff";
in
{
  imports = [
    # Include the results of the hardware scan.
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "homenastest"; # Define your hostname.

  networking.interfaces = {
    # enp1s0 = {
    #   ipv4 = {
    #     addresses = [
    #       {
    #         address = vars.ip;
    #         prefixLength = 24;
    #       }
    #     ];
    #   };
    #   useDHCP = true;
    # };
  };
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitEmptyPasswords = "yes";
      PermitRootLogin = "yes";
    };
  };
  users.users = {
    david = {
      password = "";
      openssh.authorizedKeys.keyFiles = [
        ../secrets/id_ed25519.pub
      ];
    };
    h = {
      isNormalUser = true;
      password = "";
      extraGroups = [ "wheel" ];
      shell = "${halt-shell}/bin/halt-shell";
    };
    root = {
      openssh.authorizedKeys.keyFiles = [
        ../secrets/id_ed25519.pub
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
}
