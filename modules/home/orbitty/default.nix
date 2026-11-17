{ pkgs, ... }:
let
  orbitty = pkgs.rustPlatform.buildRustPackage {
    pname = "orbitty";
    version = "unstable-2026-05-04";

    src = pkgs.fetchFromGitHub {
      owner = "aywski";
      repo = "orbitty";
      rev = "adc729de5c7624b08bdb38002d645c5afc33f795";
      hash = "sha256-yutm2W6xygnW7rNbx2NVV38tCV5clFd6N2TlZr+4JDM=";
    };

    cargoLock.lockFile = ./Cargo.lock;

    meta = {
      description = "Terminal idle screensaver — slowly spinning planets with procedural surface textures";
      homepage = "https://github.com/aywski/orbitty";
      license = pkgs.lib.licenses.mit;
      mainProgram = "orbitty";
    };
  };
in
{
  home.packages = [ orbitty ];
}
