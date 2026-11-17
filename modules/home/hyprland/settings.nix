{ lib, ... }:
let
  p = (import ../palette.nix).inkCream;
  rgba = hex: "rgba(${lib.removePrefix "#" hex}ff)";
in {
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "ch";
      kb_variant = "de";
      kb_options = "caps:escape";
      follow_mouse = 1;
      sensitivity = -0.25;
      touchpad.natural_scroll = false;
      touchpad.disable_while_typing = true;
    };

    device = [{
      name = "epic-mouse-v1";
      sensitivity = -0.5;
    }];

    # A hardware cursor keeps moving while inference saturates the GPU.
    cursor.no_hardware_cursors = false;

    general = {
      layout = "dwindle";
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
      "col.active_border" = rgba p.muted;
      "col.inactive_border" = rgba p.ink;
    };

    dwindle.preserve_split = true;
    misc.disable_hyprland_logo = true;

    decoration = {
      rounding = 10;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      # Only kitty is translucent; one pass keeps the GPU cost low.
      blur = {
        enabled = true;
        size = 6;
        passes = 1;
      };
    };

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
  };
}
