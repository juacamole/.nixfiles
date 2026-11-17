{ pkgs, inputs, username, ... }: {
  imports = [
    ./desktop.nix
    ./audio.nix
  ];

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb = {
    layout = "ch";
    variant = "";
  };
  console.keyMap = "sg";

  programs.zsh.enable = true;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" "docker" ];
    shell = pkgs.zsh;
  };

  virtualisation.docker.enable = true;
  # Lets unpatched dynamic binaries (npm packages etc.) run.
  programs.nix-ld.enable = true;
  # Capability wrapper; bandwhich needs raw sockets.
  programs.bandwhich.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      claude-code = (import inputs.nixpkgs-claude {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      }).claude-code;
    })
  ];
}
