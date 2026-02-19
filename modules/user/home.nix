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
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh.enable = true;

  home.stateVersion = "25.11";
}
