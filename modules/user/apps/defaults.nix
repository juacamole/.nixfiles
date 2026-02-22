{ pkgs, inputs, ... }: {

  # Apps that don't need special config
  home.packages = with pkgs; [
	
	# Gaming
    steam-run
    scarab 

	# Env
    inputs.zen-browser.packages."${pkgs.system}".default
    discord-ptb
    firefox
    fastfetch
    quickshell
    nwg-look

	# Coding
    gcc
    nodejs
    rustc
    rustup
    unzip
    git

	# nvim stuff
    tree-sitter
    lua-language-server
    nil
    stylua

	# Hypr stuff
    hyprlock
    waybar
	nautilus
	hyprshot
  	satty
	pkgs.swaynotificationcenter
  	wl-clipboard
    pavucontrol
    rofi
    swww
  ];
}
