{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    secret = {
      url = "/etc/nixos/secret";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      commonModules = [
        ./common.nix
        ./service/coredns.nix
        ./service/openldap.nix
        ./service/sftp.nix
        ./service/k3s.nix
        {
          _module.args = {
            secret = inputs.secret;
            inputs = inputs;
          };
        }
      ];
    in
    {

      nixosConfigurations.homenas = nixpkgs.lib.nixosSystem {
        modules = commonModules ++ [
          ./nas/configuration.nix
          ./nas/hardware-configuration.nix
          {
            _module.args.vars = import ./nas/vars.nix;
          }
        ];
      };
      nixosConfigurations.homenastest = nixpkgs.lib.nixosSystem {
        modules = commonModules ++ [
          ./homenastest/configuration.nix
          ./homenastest/hardware-configuration.nix
          {
            _module.args.vars = import ./homenastest/vars.nix;
          }
        ];
      };
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
