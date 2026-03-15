{ ... }:
let
  goldBright = "dac48aff";
  goldMid = "c8b078ff";
  goldDim = "8b7355ff";
  panelBg = "3a2a18ff";
  inactive = "4a3828ff";
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
    cursor.no_hardware_cursors = true;
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
      rounding = 0;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      blur = {
        enabled = false;
        size = 3;
        passes = 1;
      };
    };
    general = {
      gaps_in = 0;
      gaps_out = 0;
      border_size = 1;
      "col.active_border" = "rgba(${goldBright}) rgba(${goldDim}) 45deg";
      "col.inactive_border" = "rgba(${inactive})";
      layout = "dwindle";
    };
    misc.disable_hyprland_logo = true;
    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };
  };
}
