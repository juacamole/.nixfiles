{ pkgs, ... }:
let
  name = "Bibata-Modern-Classic";
  size = 22;
in {
  home.pointerCursor = {
    enable = true;
    inherit name size;
    package = pkgs.bibata-cursors;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland.settings.env = [
    "XCURSOR_THEME,${name}"
    "XCURSOR_SIZE,${toString size}"
    "HYPRCURSOR_THEME,${name}"
    "HYPRCURSOR_SIZE,${toString size}"
  ];
}
