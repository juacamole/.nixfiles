{ config, pkgs, ... }: {
  imports = [ 
    ./hardware-configuration.nix
    ../../modules/system/boot.nix
    ../../modules/system/desktop.nix
    ../../modules/system/audio.nix
  ];

  # Basic System Settings
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Locale/Keyboard
  services.xserver.xkb = { layout = "ch"; variant = ""; };
  console.keyMap = "sg";

  # User Definition
  users.users.kuan = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;
    };

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";}
