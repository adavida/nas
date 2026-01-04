# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  vars = import ../vars.nix;
in
{
  imports = [
    # Include the results of the hardware scan.

  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homenas"; # Define your hostname.
  networking.nameservers = [ vars.ip ];

  networking.interfaces = {
    enp1s0 = {
      ipv4 = {
        addresses = [
          {
            address = vars.ip;
            prefixLength = 24;
          }
        ];
      };
      useDHCP = true;
    };
  };

  fileSystems."/srv/borg/home" = {
    device = "/data/main/borg/home";
    options = [ "bind" ];
  };

}
