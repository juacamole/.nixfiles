{ pkgs, ... }:
let
  # `awww img` does nothing until the daemon's socket is up.
  setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
    ${pkgs.awww}/bin/awww-daemon &
    until ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do sleep 0.1; done
    exec ${pkgs.awww}/bin/awww img ~/Pictures/wallpaper/wallpaper.png --transition-type fade
  '';
in {
  imports = [
    ./settings.nix
    ./binds.nix
    ./rules.nix
    ./hyprlock.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # home-manager's default generator is now Lua; this config is hyprlang.
    configType = "hyprlang";

    settings = {
      # quickshell and hypridle are systemd user units, not exec-once.
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${setWallpaper}"
      ];

      env = [
        "XDG_SESSION_TYPE, wayland"
        "ELECTRON_OZONE_PLATFORM_HINT, auto"
      ];
    };
  };
}
