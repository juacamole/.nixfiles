{ inputs, pkgs, ... }:
let
  p = (import ./palette.nix).inkCream;
in {
  imports = [ inputs.gazelle.homeModules.gazelle ];

  home.packages = [
    inputs.gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.gazelle = {
    enable = true;
    settings.theme = "user-theme";
  };

  # Gazelle reads only these four keys. `red` is its focus colour, set to
  # yellow so focus looks the same as everywhere else.
  xdg.configFile."gazelle/theme.toml".text = ''
    [colors.primary]
    foreground = "${p.bright}"
    background = "${p.base}"
    [colors.normal]
    red = "${p.yellow}"
    yellow = "${p.yellow}"
  '';
}
