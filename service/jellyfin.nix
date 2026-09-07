{
  config,
  lib,
  pkgs,
  secrets,
  vars,
  ...
}:
{
  fileSystems."/srv/jellyfin/videos" = {
    device = "/data/2/videos";
    fsType = "none";
    options = [
      "bind"
      "ro"
      "nofail"
    ];
    depends = [ "/data/2" ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
    ];
  };

  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];

  systemd.services.jellyfin.serviceConfig = {
    ProtectSystem = lib.mkForce "strict";
    ProtectHome = lib.mkForce "tmpfs";
    PrivateTmp = lib.mkForce true;
    PrivateMounts = lib.mkForce true;
    ProtectKernelTunables = lib.mkForce true;
    ProtectKernelModules = lib.mkForce true;
    ProtectControlGroups = lib.mkForce true;
    LockPersonality = lib.mkForce true;
    RestrictSUIDSGID = lib.mkForce true;
    NoNewPrivileges = lib.mkForce true;
    # ponytail: "-" prefix ignores missing dirs on homenastest (e.g. /var/log/jellyfin)
    ReadWritePaths = [
      "-/var/lib/jellyfin"
      "-/var/cache/jellyfin"
      "-/var/log/jellyfin"
    ];
    BindReadOnlyPaths = [
      "-/srv/jellyfin"
    ];
    InaccessiblePaths = [
      "-/data"
      "-/srv/borg"
      "-/sftp"
      "-/home"
    ];
    TemporaryFileSystem = lib.mkForce "/:ro";
    LogsDirectory = "jellyfin";
    CacheDirectory = "jellyfin";
    StateDirectory = "jellyfin";

    PrivateDevices = lib.mkForce false;
    DevicePolicy = lib.mkForce "closed";
    DeviceAllow = lib.mkForce [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
      "char-drm rw"
    ];
  };

  services.jellyfin = {
    enable = true;
  };

  services.nginx.virtualHosts."jellyfin.${vars.base_host}" = {
    forceSSL = true;
    sslCertificate = "${secrets}/certs/_wildcard.${vars.base_host}.crt";
    sslCertificateKey = "${secrets}/certs/_wildcard.${vars.base_host}.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
}
