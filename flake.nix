{
  description = "My NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lexis.url = "github:EmanuelPeixoto/Lexis";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

  in {
    nixosConfigurations = {
      NixOS-ZimaCube = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./system
          home-manager.nixosModules.home-manager
        ];
        specialArgs = { inherit inputs; };
      };
    };
    homeConfigurations = {
      zimacube = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./hm ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
  };
}
