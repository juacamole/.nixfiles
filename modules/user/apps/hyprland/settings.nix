{ ... }: {
  wayland.windowManager.hyprland.settings = {
    # input
    input = {
      kb_layout = "ch";
      kb_variant = "de";
      follow_mouse = 1;
      sensitivity = -0.25;
      touchpad.natural_scroll = false;
	  kb_options = caps:escape;
    };

    device = [{
      name = "epic-mouse-v1";
      sensitivity = -0.5;
    }];

    cursor.no_hardware_cursors = true;

    # animations
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

    # decorations & variables
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
      "col.active_border" = "rgba(eeeeeeff) rgba(ffffffff) 45deg";
      "col.inactive_border" = "rgba(333333ff)";
      layout = "dwindle";
    };

    misc.disable_hyprland_logo = true;
    
    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };
  };
}
