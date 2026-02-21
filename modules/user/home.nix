{ pkgs, inputs, username, ... }: { 

  imports = [
    ./apps/kitty.nix
    ./apps/hyprland/default.nix
    ./apps/zsh.nix
  ];

  home.username = "kuan";
  home.homeDirectory = "/home/kuan";

  # Apps that don't need special config
  home.packages = with pkgs; [
    neovim
    fastfetch
    firefox
    waybar
    wofi
    nwg-look
    hyprlock
    git
    quickshell
    rustc
    rustup
    discord-ptb
    pavucontrol
    gcc
    ly
    scarab 
    steam-run
    inputs.zen-browser.packages."${pkgs.system}".default
    swww
  ];

  home.sessionVariables = {
    STEAM_EXTRA_COMPAT_RUNTIME_PATHS = "/home/kuan/.steam/root/compatibilitytools.d";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.zsh.enable = true;

  home.stateVersion = "25.11";
}
