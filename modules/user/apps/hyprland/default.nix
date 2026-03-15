{ pkgs, ... }: {
  imports = [
    ./monitors.nix
    ./settings.nix
    ./binds.nix
    ./rules.nix
	./hyprlock.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
	source = [ "~/.config/hypr/monitors.conf" ];
      # Autostart
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "swww img $(find ~/Pictures/wallpapers -type f | shuf -n 1) --transition-type outer --transition-pos 0.85,0.85"
        "swww-daemon"
        "~/bash/tanatos/tanatos.sh"
		"hypridle"
		"swaync"
		"waybar"
      ];

      # Environment
      env = [
        "XDG_SESSION_TYPE, wayland"
        "LIBVA_DRIVER_NAME, nvidia"
        "GBM_BACKEND, nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME, nvidia"
        "ELECTRON_OZONE_PLATFORM_HINT, auto"
      ];

      xwayland = {
        force_zero_scaling = true;
      };
    };
  };
}
