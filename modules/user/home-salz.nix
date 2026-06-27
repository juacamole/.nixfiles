{ pkgs, inputs, username, ... }: {

  # Mac (salz) home entry. Mirrors home.nix but drops:
  #   - orbitty (x86-only local pkg)
  #   - the nvidia GPU session variables
  # Per-package stripping (gaming, nbfc-linux) and per-host tweaks
  # (monitors, battery, hyprland env) are handled inside the shared app
  # modules, gated on hostKind == "mac".
  imports = [
    ./apps/kitty.nix
    ./apps/hyprland/default.nix
    ./apps/zsh.nix
	./apps/defaults.nix
	./apps/hypridle.nix
	inputs.nixvim.homeModules.nixvim
	./apps/nvim/default.nix
	./apps/rofi.nix
	./apps/gazelle.nix
	./apps/claude.nix
	./apps/quickshell.nix
	./apps/cursor.nix
	./apps/notifications.nix
	./apps/battery.nix
	./apps/ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_RUNTIME_PATHS = "/home/${username}/.steam/root/compatibilitytools.d";
    _JAVA_AWT_WM_NONREPARENTING = "1";

    NPM_CONFIG_PREFIX = "/home/${username}/.npm-global";
  };

  home.sessionPath = [
    "/home/${username}/.npm-global/bin"
  ];

  programs.zsh.enable = true;

	programs.direnv = {
	  enable = true;
	  nix-direnv.enable = true;
	};

  home.stateVersion = "25.11";
}
