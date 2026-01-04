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
    in
    {

      nixosConfigurations.homenas = nixpkgs.lib.nixosSystem {
        modules = [
          ./common.nix
          ./nas/configuration.nix
          ./nas/hardware-configuration.nix
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
      };
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
