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
  services.xserver.xkb = { 
    layout = "ch"; 
    variant = ""; 
  };
  console.keyMap = "sg";

  # Shell Configuration
  programs.zsh.enable = true;

  # Display manager for login manager ig
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
        user = "greeter";
      };
    };
  };

  # Also some shi to prevent login mgr to show errors
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
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;
  };

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  # Enable Flakes and the 'nix' command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow proprietary software 
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
