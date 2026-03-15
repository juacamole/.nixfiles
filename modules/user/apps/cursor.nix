{ pkgs, ... }:
{
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 22;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland.settings = {
    env = [
      "XCURSOR_THEME,Bibata-Modern-Classic"
      "XCURSOR_SIZE,22"
      "HYPRCURSOR_THEME,Bibata-Modern-Classic"
      "HYPRCURSOR_SIZE,22"
    ];
  };
}
