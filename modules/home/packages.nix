{ pkgs, lib, inputs, ... }: {
  home.packages = with pkgs; [
    # Desktop apps
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    firefox
    nautilus
    obs-studio
    vesktop
    prismlauncher
    projectlibre
    ani-cli

    # Session tools
    awww
    brightnessctl
    hyprshot
    wl-clipboard
    pavucontrol
    nwg-look
    nwg-displays
    impala
    iwd

    # Wacom
    xf86_input_wacom
    libwacom

    # CLI
    tree
    yazi
    glow
    unzip
    ripgrep
    fd
    psmisc
    btop
    dust
    duf
    lsof
    watchexec
    nix-output-monitor

    # Dev
    git
    git-lfs
    lazygit
    jujutsu
    jjui
    docker
    mosquitto
    lazysql
    opencode
    crush
    nodejs
    rustup
    openjdk
    maven
    gradle
    godot

    # C / C++
    (lib.hiPrio gcc)
    clang_18
    clang-tools
    cmake
    ninja
    gnumake
    gdb
    lldb
  ];
}
