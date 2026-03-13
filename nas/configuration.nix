# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  vars,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.

  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homenas"; # Define your hostname.
  networking.nameservers = [ vars.ip_local ];

  networking.interfaces = {
    enp1s0 = {
      ipv4 = {
        addresses = [
          {
            address = vars.ip_local;
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
