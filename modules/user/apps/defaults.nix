{ pkgs, lib, inputs, hostKind, ... }:
let
  # x86 desktop (pommes) gets gaming + Acer fan control; the Mac (salz) skips
  # them. Items stay in their ORIGINAL list positions so the pommes profile
  # buildEnv hashes identically to before the refactor.
  isDesktop = hostKind == "nvidia";
in {

  # Apps that don't need special config
  home.packages = with pkgs;
    lib.optionals isDesktop [
      # Gaming
      steam-run
      scarab
    ]
    ++ lib.optionals isDesktop [
      discord-ptb
    ]
    ++ [
      # Env
      inputs.zen-browser.packages."${pkgs.system}".default
      firefox
      fastfetch
      quickshell
      nwg-look
      impala
      iwd
      tree
      yazi
      obs-studio
    ]
    ++ lib.optionals isDesktop [
      nbfc-linux
    ]
    ++ [
      krita
      docker

      # wacom
      xf86_input_wacom
      libwacom

	  # bored
	  ani-cli

      # Useless
      projectlibre

	  # gaming 2
      prismlauncher
	  vesktop



      # Coding
	  lazysql
      (lib.hiPrio gcc)
	  maven
      nodejs
      rustup
      unzip
      git
	  git-lfs
	  jujutsu
	  jjui
      openjdk
      gradle
      lazygit
	  godot
	  opencode
	  crush
	  # cpp
	  clang_18 cmake ninja
	  clang-tools
	  gdb lldb
	  gnumake


      # nvim stuff
      tree-sitter
      lua-language-server
      nil
      stylua

      # Hypr stuff
	  brightnessctl
      nautilus
      hyprshot
      satty
      wl-clipboard
      pavucontrol
      awww
      nwg-displays
    ];
}
