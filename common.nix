{
  config,
  pkgs,
  inputs,
  secret,
  ssh_borg_key,
  ...
}:
{
  services.tailscale.enable = true;
  system.autoUpgrade = {
    enable = false;
    dates = "hourly";
    flake = "github:adavida/nas";
    randomizedDelaySec = "5min";
    allowReboot = true;
    upgrade = false;
    persistent = true;
    runGarbageCollection = true;
  };

  systemd.services.nixos-upgrade = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users = {
    david = {
      isNormalUser = true;
      description = "david";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };
    borg = {
      isNormalUser = true;
      description = "borg";
      extraGroups = [ ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./secrets/ssh_borg_key)
      ];
      packages = with pkgs; [ ];
      uid = 1002;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git

    bat
    borgbackup
    dig
    gnumake
    hddtemp
    openssl
    ripgrep
    tree

  ];
  services.openssh = {
    ports = [ 220 ];
    enable = true;
  };

  system.stateVersion = "25.11"; # Did you read the comment?

}
