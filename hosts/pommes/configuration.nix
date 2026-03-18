{ config, pkgs, ... }: {
  imports = [ 
    ./hardware-configuration.nix
    ./grub.nix
    ../../modules/system/boot.nix
    ../../modules/system/desktop.nix
    ../../modules/system/audio.nix
  ];

  # Basic System Settings
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  
  services.xserver.xkb = { 
    layout = "ch"; 
    variant = ""; 
  };
  # load nvidia driver
  services.xserver.videoDrivers = ["nvidia"]; 
  console.keyMap = "sg";

  # nvidia graphic config
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; 
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";    
      nvidiaBusId = "PCI:1:0:0"; 
    };
  };

  # Shell Configuration
  programs.zsh.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Login Manager
  services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      user = "kuan";
        };
      };
   };
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # User Definition
  users.users.kuan = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" ]; 
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

  system.stateVersion = "25.11";
}
