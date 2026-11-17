{ ... }:
let
  # "Ink & cream" set, shared with the quickshell bar. Flat and calm: space
  # gray outline for the focused window, near-black ink for the rest. (Yellow
  # was tried here and read too loud at window scale.)
  activeGray = "6b6780ff";
  inactiveInk = "0f0e13ff";
in
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "ch";
      kb_variant = "de";
      follow_mouse = 1;
      sensitivity = -0.25;
      touchpad.natural_scroll = false;
      touchpad.disable_while_typing = true;
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
      # Blur only does work behind surfaces with alpha: today that's just
      # kitty (background_opacity 0.88). The bar and other windows are opaque,
      # so they cost nothing. Kept light (1 pass) since GPU time is scarce
      # here; without blur the see-through terminal reads as noise.
      blur = {
        enabled = true;
        size = 6;
        passes = 1;
      };
    };
    general = {
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
      "col.active_border" = "rgba(${activeGray})";
      "col.inactive_border" = "rgba(${inactiveInk})";
      layout = "dwindle";
    };
    misc.disable_hyprland_logo = true;
    dwindle = {
      preserve_split = true;
    };
  };
}
