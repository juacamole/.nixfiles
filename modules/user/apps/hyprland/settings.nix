{ ... }:
let
  activeWhite = "f5f5f5ff";
  activeGray = "c8c8c8ff";
  inactiveGray = "4a4a4aff";
in
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "ch";
      kb_variant = "de";
      follow_mouse = 1;
      sensitivity = -0.25;
      touchpad.natural_scroll = false;
      kb_options = "caps:escape";
    };
    device = [{
      name = "epic-mouse-v1";
      sensitivity = -0.5;
    }];
    # Software cursors are composited by Hyprland on the GPU, so while ollama
    # saturates it the pointer itself freezes — the single most "unusable"
    # symptom. A hardware cursor lives on its own DCP plane and keeps moving
    # at full rate no matter how backed up the render queue is. Revert to
    # true if the pointer corrupts or vanishes on Asahi.
    cursor.no_hardware_cursors = false;
    animations = {
      enabled = true;
      bezier = [ "overshot, 0.13, 0.99, 0.29, 1.1" ];
      animation = [
        "windowsIn, 1, 2, default, slidefade 100%"
        "windowsOut, 1, 1, default, popin 80%"
        "border, 1, 1, default"
        "workspacesIn, 1, 2, default, slide"
        "workspacesOut, 1, 2, default, slidefade 80%"
      ];
    };
    decoration = {
      rounding = 10;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      blur = {
        enabled = false;
        size = 3;
        passes = 1;
      };
    };
    general = {
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
      "col.active_border" = "rgba(${activeWhite}) rgba(${activeGray}) 45deg";
      "col.inactive_border" = "rgba(${inactiveGray})";
      layout = "dwindle";
    };
    misc.disable_hyprland_logo = true;
    dwindle = {
      preserve_split = true;
    };
  };
}
