{
  description = "NixOS config juacamole";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
	actions-preview = {
      url = "github:aznhe21/actions-preview.nvim";
      flake = false;
    };
	gazelle.url = "github:Zeus-Deus/gazelle-tui";

	# Asahi / Apple Silicon support. NO nixpkgs.follows on purpose:
	# upstream pins a tested nixpkgs + binary cache for the Asahi kernel;
	# overriding it forces a multi-hour kernel compile.
	apple-silicon.url = "github:nix-community/nixos-apple-silicon";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    username = "kuan";

    mkHost = { hostname, system, hostKind, flakeTarget, homeModule, extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          { nixpkgs.hostPlatform = system; }

          ./hosts/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import homeModule;

            home-manager.extraSpecialArgs = {
              inherit inputs username hostKind flakeTarget;
            };

            home-manager.backupFileExtension = "backup";
          }
        ] ++ extraModules;
      };

    hosts = {
      pommes = mkHost {
        hostname = "pommes";
        system = "x86_64-linux";
        hostKind = "nvidia";
        flakeTarget = "main";
        homeModule = ./modules/user/home.nix;
      };

      salz = mkHost {
        hostname = "salz";
        system = "aarch64-linux";
        hostKind = "mac";
        flakeTarget = "salz";
        homeModule = ./modules/user/home-salz.nix;
        extraModules = [ inputs.apple-silicon.nixosModules.apple-silicon-support ];
      };
    };
  in {
    templates = {
      rust    = { path = ./templates/rust;    description = "Rust dev shell"; };
      cpp     = { path = ./templates/cpp;     description = "C++ dev shell"; };
      generic = { path = ./templates/generic; description = "Generic dev shell"; };
      default = self.templates.generic;
    };

    # `main` kept as an alias of `pommes` so `.#main` keeps working.
    nixosConfigurations = hosts // { main = hosts.pommes; };
  };
}
