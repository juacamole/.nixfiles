{ pkgs, inputs, ... }: {

  # Apps that don't need special config
  home.packages = with pkgs; [
	
	# Gaming
    steam-run
    scarab 
	prismlauncher

	# Env
    inputs.zen-browser.packages."${pkgs.system}".default
    discord-ptb
    firefox
    fastfetch
    quickshell
    nwg-look
	mako
	impala
	iwd
	tree
	yazi
	obs-studio

	# Useless
	projectlibre
	
	# Coding
    gcc
    nodejs
    rustc
    rustup
    unzip
    git
	openjdk
	gradle
	docker

	# nvim stuff
    tree-sitter
    lua-language-server
    nil
    stylua

	# Hypr stuff
    waybar
	nautilus
	hyprshot
  	satty
  	wl-clipboard
    pavucontrol
    rofi
    swww
	nwg-look
    nwg-displays
  ];
}
