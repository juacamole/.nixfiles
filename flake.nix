{
  description = "NixOS config juacamole";

  inputs = {
    # Where Nix gets its packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

outputs = { self, nixpkgs, home-manager, ... }@inputs: 
let
  username = "kuan";
  system = "x86_64-linux";
in {
  nixosConfigurations.main = nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs username; }; 
    modules = [
      ./hosts/nixos/configuration.nix
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./modules/home.nix;
        home-manager.extraSpecialArgs = { inherit username; };
      }
    ];
  };
};
