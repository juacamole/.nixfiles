{
  description = "NixOS config juacamole";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Only claude-code is taken from here, so it can be bumped alone.
    nixpkgs-claude.url = "github:nixos/nixpkgs/master";
    # No nixpkgs.follows: upstream pins the nixpkgs its Asahi kernel cache was built from.
    apple-silicon.url = "github:nix-community/nixos-apple-silicon";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    allam = {
      url = "github:juacamole/allam";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    actions-preview = {
      url = "github:aznhe21/actions-preview.nvim";
      flake = false;
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    gazelle.url = "github:Zeus-Deus/gazelle-tui";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      username = "kuan";

      mkHost = hostname: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs username; };
              users.${username} = import ./hosts/${hostname}/home.nix;
            };
          }
        ];
      };

      hosts = nixpkgs.lib.genAttrs [ "salz" ] mkHost;
    in {
      nixosConfigurations = hosts;

      templates = {
        rust = { path = ./templates/rust; description = "Rust dev shell"; };
        cpp = { path = ./templates/cpp; description = "C++ dev shell"; };
        python = { path = ./templates/python; description = "Python dev shell with numpy"; };
        generic = { path = ./templates/generic; description = "Generic dev shell"; };
        default = self.templates.generic;
      };
    };
}
