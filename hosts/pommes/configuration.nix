{ config, pkgs, username, ... }: {
  imports = [ 
    ./hardware-configuration.nix
    ./grub.nix
    ../../modules/system/boot.nix
    ../../modules/system/desktop.nix
    ../../modules/system/audio.nix
  ];

  # Basic System Settings
  networking.hostName = "pommes";
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
  hardware.graphics.enable32Bit = true;

  # Unmute internal HDA on this Acer (relocated from shared audio.nix).
  systemd.services.unmute-headphone = {
    description = "Unmute ALSA Headphone switch on internal HDA";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" "pipewire.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset Master unmute 80%
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset Headphone unmute 80%
    '';
  };

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
      user = username;
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
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" "docker" ];
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
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  virtualisation.docker.enable = true;

  # Allow running unpatched dynamic binaries (npm packages, etc.)
  programs.nix-ld.enable = true;

  # Use patched system GLFW/OpenAL for PrismLauncher (fixes broken LWJGL GLFW)
  environment.sessionVariables = {
    PRISMLAUNCHER_USE_SYSTEM_GLFW = "1";
    PRISMLAUNCHER_USE_SYSTEM_OPENAL = "1";
  };

  system.stateVersion = "25.11";
}
