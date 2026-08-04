{ pkgs, lib, hostKind, ... }:
let
  isDesktop = hostKind == "nvidia";

  # `awww img` races `awww-daemon` startup — without waiting for the socket,
  # the wallpaper command silently no-ops and the screen stays blank.
  setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
    ${pkgs.awww}/bin/awww-daemon &
    until ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do sleep 0.1; done
    exec ${pkgs.awww}/bin/awww img ~/Pictures/wallpaper/wallpaper.png --transition-type fade
  '';
in
{
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
    # Pin the legacy hyprlang generator; Zoko/HM flipped the default to "lua".
    configType = "hyprlang";

    settings = {
	# monitors.conf is a pommes-local override (live-edited outside the
	# flake). salz monitor config lives declaratively in monitors.nix.
	source = lib.optionals isDesktop [ "~/.config/hypr/monitors.conf" ];
      # Autostart. Quickshell ("kuan" config) provides bar, launcher,
      # notifications, and OSDs on both hosts. tanatos stays pommes-only.
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${setWallpaper}"
		"hypridle"
		"qs -c kuan -d"
      ] ++ lib.optionals isDesktop [
        "~/bash/tanatos/tanatos.sh"
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

      # force_zero_scaling makes Xwayland clients render at 1x (we upscale).
      # On the muvm/FEX/Asahi stack this collides with Steam CEF's own
      # -forcedesktopscaling, producing rendering glitches in webhelper
      # subwindows. Keep it only on the desktop where it's needed.
      xwayland = {
        force_zero_scaling = isDesktop;
      };
    };
  };
}
