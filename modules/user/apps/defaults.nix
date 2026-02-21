{ pkgs, inputs, ... }: {

  # Apps that don't need special config
  home.packages = with pkgs; [
    neovim
    fastfetch
    firefox
    waybar
    rofi
    nwg-look
    hyprlock
    git
    quickshell
    rustc
    rustup
    discord-ptb
    pavucontrol
    gcc
    scarab 
    steam-run
    inputs.zen-browser.packages."${pkgs.system}".default
    swww
    unzip
    lua-language-server
    stylua
    nil
    tree-sitter
    nodejs
		hyprshot
  	satty
  	wl-clipboard
		pkgs.swaynotificationcenter
		nautilus
  ];
}
