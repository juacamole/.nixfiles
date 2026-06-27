{ pkgs, lib, hostKind, ... }: {
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
        "awww-daemon"
        "awww img ~/Pictures/wallpapers/higurama.jpg --transition-type fade"
        "~/bash/tanatos/tanatos.sh"
		"hypridle"
		"swaync"
		"qs -c hiromi -d"
      ];

      # Environment
      env = [
        "XDG_SESSION_TYPE, wayland"
      ] ++ lib.optionals (hostKind == "nvidia") [
        "LIBVA_DRIVER_NAME, nvidia"
        "GBM_BACKEND, nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME, nvidia"
      ] ++ [
        "ELECTRON_OZONE_PLATFORM_HINT, auto"
      ];

      xwayland = {
        force_zero_scaling = true;
      };
    };
  };
}
