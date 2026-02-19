{ pkgs, ... }: {

  imports = [
  ./apps/kitty.nix
  ./apps/hyprland/default.nix
  ./apps/zsh.nix
  ];

  home.username = "kuan";
  home.homeDirectory = "/home/kuan";

  # Apps that don't need special config
  home.packages = with pkgs; [
    vim
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
  ];

  # This links Hyprland to the config
#  xdg.configFile."hypr".source = ../../config/hypr;

  programs.zsh.enable = true;

  home.stateVersion = "25.11";
}
