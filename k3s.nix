{ config, pkgs, ... }:
let 
    vars = import ./vars.nix;
in { 
    networking.firewall.allowedTCPPorts = [
      6443 # k3s
    ];
    services.k3s = {
        enable = true;
        role = "server";
        extraFlags = "--write-kubeconfig-mode 644 --disable=traefik";
        manifests."ingress" = {
          source = ./manifest/ingress.yaml;
          enable = true;
        };
    };
}
