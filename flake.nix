{
  description = "NixOS config juacamole";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
          home-manager.users.${username} = import ./modules/user/home.nix;
          home-manager.extraSpecialArgs = { inherit username; };
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  };
}
