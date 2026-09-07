{
  config,
  pkgs,
  secrets,
  vars,
  ...
}:
{
  fileSystems."/srv/jellyfin/videos" = {
    device = "/data/2/videos";
    fsType = "none";
    options = [ "bind" "ro" ];
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
    ProtectSystem = "strict";
    ProtectHome = "tmpfs";
    PrivateTmp = true;
    PrivateMounts = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictSUIDSGID = true;
    NoNewPrivileges = true;

    ReadWritePaths = [
      "/var/lib/jellyfin"
      "/var/cache/jellyfin"
      "/var/log/jellyfin"
    ];
    BindReadOnlyPaths = [ "/srv/jellyfin" ];
    InaccessiblePaths = [
      "/data"
      "/srv/borg"
      "/sftp"
      "/home"
    ];
    TemporaryFileSystem = "/:ro";

    PrivateDevices = false;
    DevicePolicy = "closed";
    DeviceAllow = [
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
