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
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "homenastest"; # Define your hostname.

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
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };
}
