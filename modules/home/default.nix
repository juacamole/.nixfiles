{ inputs, username, ... }:
let
  home = "/home/${username}";
in {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./packages.nix
    ./zsh.nix
    ./kitty.nix
    ./ssh.nix
    ./pass.nix
    ./claude.nix
    ./gazelle.nix
    ./fastfetch
    ./nvim
    ./hyprland
    ./hypridle.nix
    ./quickshell
    ./battery.nix
    ./theme.nix
    ./cursor.nix
  ];

  home = {
    inherit username;
    homeDirectory = home;
    stateVersion = "25.11";

    sessionVariables = {
      STEAM_EXTRA_COMPAT_RUNTIME_PATHS = "${home}/.steam/root/compatibilitytools.d";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      NPM_CONFIG_PREFIX = "${home}/.npm-global";
    };

    sessionPath = [
      "${home}/.npm-global/bin"
      "${home}/go/bin"
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
