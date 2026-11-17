{ ... }:
{
  # Package itself comes from defaults.nix; this only ships the config.
  xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;
}
