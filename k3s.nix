{ config, pkgs, ... }:
let 
    vars = import ./vars.nix;
in { 
    networking.firewall.allowedTCPPorts = [
      6443 # k3s
    ];
    
    systemd.services."k3s".after = [ "openldap.service" ];
    
    services.k3s = {
        enable = true;
        role = "server";
        extraFlags = "--write-kubeconfig-mode 644 --disable=traefik";
        # manifests."ingress" = {
        #   source = ./manifest/ingress.yaml;
        #   enable = true;
        # };
    };
}
