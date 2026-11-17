{ inputs, pkgs, ... }:
{
  imports = [ inputs.gazelle.homeModules.gazelle ];

  home.packages = [
    inputs.gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.gazelle = {
    enable = true;
    settings = {
      theme = "user-theme";
    };
  };

  # "Ink & cream" palette for gazelle's "user-theme". Gazelle only reads four
  # keys: primary.{foreground,background}, normal.yellow (accent) and
  # normal.red (Textual "primary": focus borders, header). red is set to the
  # yellow accent on purpose so focus reads yellow like everywhere else.
  xdg.configFile."gazelle/theme.toml".text = ''
    [colors.primary]
    foreground = "#ece6d8"
    background = "#1d1c24"
    [colors.normal]
    red = "#e6c88a"
    yellow = "#e6c88a"
  '';
}
