{
  description = "My NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lexis = {
      url = "github:EmanuelPeixoto/Lexis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
        overlays = [
          (final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              config.cudaSupport = true;
            };
          })
        ];
      };

      # Lista dos sistemas para gerar configurações
      systems = [ "zimacube" ];

      # Função para gerar uma configuração NixOS
      mkNixosSystem = name:
        nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [
            ./system
          ];
          specialArgs = { inherit inputs; };
        };

      # Função para gerar uma configuração do Home Manager
      mkHomeConfig = name:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hm ];
          extraSpecialArgs = { inherit inputs; };
        };

    in {
      nixosConfigurations = {
        NixOS-ZimaCube = mkNixosSystem "zimacube";
      };

      homeConfigurations = nixpkgs.lib.genAttrs systems (name: mkHomeConfig name);
    };
}
