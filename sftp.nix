{ config, pkgs, ... }:
let 
    vars = import ./vars.nix;
in{
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "ens3";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };
  networking.firewall.allowedTCPPorts = [ 222 ];
  
  # fileSystems."/sftp/david/photo" = {
  #   device = "/data/main/photo";
  #   options = [ "bind" ];
  # };

  containers.sftp = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    hostAddress6 = "fc00::1";
    localAddress6 = "fc00::2";
    forwardPorts = [
      {
        containerPort = 222;
        hostPort = 222;
        protocol = "tcp";
      }
    ];

    bindMounts = {
      "/etc/nixos/secret/olcRootPW" = {
        hostPath = "/etc/nixos/secret/olcRootPW";        
        mountPoint = "/etc/nixos/secret/olcRootPW";
      };
      "/sftp" = {
        hostPath = "/sftp";
        mountPoint = "/sftp";
        isReadOnly = false;
      };
      # "/sftp/borg" = {
      #   hostPath = "/data/main/borg/";
      #   mountPoint = "/sftp/borg";
      #   isReadOnly = false;
      # };
    };
    config = { config, pkgs, lib, ... }: {

      system.stateVersion = "24.11";
      users = {
        ldap = {
          enable = true;        
          daemon.enable = true;
          base = "${vars.base_dn}";
          bind.distinguishedName = "cn=admin,${vars.base_dn}";
          bind.passwordFile = "/etc/nixos/secret/olcRootPW";
          server = "ldap://192.168.100.10";
          useTLS = true;
          extraConfig = ''
            ldap_version 3
            # pam_password md5
            validnames /.*/i
          '';
        };
      };
      security.pam.services.sshd.makeHomeDir = true;
      security.pam.services.login.makeHomeDir = true;
      security.pam.services.systemd-user.makeHomeDir = true;
      systemd.services.nslcd = {
        after = [ "Network-Manager.service" ];
      };

      services.openssh = {
        enable = true;
        ports = [ 222 ];
        openFirewall = true;
        allowSFTP = true;
        settings = {
          PasswordAuthentication = true;
        #   AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
        #   UseDns = true;
          X11Forwarding = false;
          PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          ForceCommand  = "internal-sftp";
          ChrootDirectory = "/sftp/%u";
        };
      };
      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 222 ];
        };
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };
      
      services.resolved.enable = true;

    };
  };
}