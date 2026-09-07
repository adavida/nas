{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # secret = {
    #   url = "/etc/nixos/secret";
    #   flake = false;
    # };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      commonModules = [
        ./common.nix
        ./service/authelia.nix
        ./service/clamav.nix
        ./service/collabora.nix
        ./service/coredns.nix
        ./service/immich.nix
        ./service/jellyfin.nix
        ./service/nextcloud.nix
        ./service/nginx.nix
        ./service/openldap.nix
        ./service/sftp.nix
        {
          _module.args = {
            path = {
              secrets = "/etc/nixos/secrets";
              keys = "/etc/nixos/key";
            };
            secrets = "/etc/nixos/secrets";
            inputs = inputs;
            outPath = self;
          };
        }
      ];
      vars = {
        clamav_socket = "/run/clamav/clamd.ctl";
      };
    in
    {
      nixosConfigurations = {
        homenas = nixpkgs.lib.nixosSystem {
          modules = commonModules ++ [
            ./nas/configuration.nix
            ./nas/hardware-configuration.nix
            {
              _module.args.vars = import ./nas/vars.nix // vars;
            }
          ];
        };
        homenastest = nixpkgs.lib.nixosSystem {
          modules = commonModules ++ [
            ./homenastest/configuration.nix
            ./homenastest/hardware-configuration.nix
            ./homenastest/vm.nix
            {
              _module.args.vars = import ./homenastest/vars.nix // vars;
            }
          ];
        };
      };
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      apps = {
        ${system}.default = {
          type = "app";
          program = "${inputs.self.nixosConfigurations.homenastest.config.system.build.vm}/bin/run-homenastest-vm";
        };
      };
    };

}
