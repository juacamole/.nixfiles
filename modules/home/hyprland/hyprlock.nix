{ lib, ... }:
let
  p = (import ../palette.nix).night;

  rgba = hex:
    let channel = i: toString (lib.fromHexString (builtins.substring i 2 hex));
    in "rgba(${channel 1}, ${channel 3}, ${channel 5}, 1.0)";
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        grace = 0;
        no_fade_in = false;
        no_fade_out = false;
      };

      background = [{
        monitor = "";
        path = "~/Pictures/wallpaper/wallpaper.png";
        blur_passes = 4;
        blur_size = 6;
        brightness = 0.7;
        vibrancy = 0.1;
      }];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = rgba p.bright;
          font_size = 72;
          font_family = "Cinzel Bold";
          position = "0, 180";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 4;
          shadow_color = "rgba(0, 0, 0, 0.5)";
          shadow_boost = 1.0;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date '+%A, %d %B %Y'";
          color = rgba p.text;
          font_size = 14;
          font_family = "Cinzel";
          position = "0, 120";
          halign = "center";
          valign = "center";
          shadow_passes = 1;
          shadow_size = 2;
          shadow_color = "rgba(0, 0, 0, 0.4)";
        }
      ];

      input-field = [{
        monitor = "";
        size = "280, 44";
        position = "0, 30";
        halign = "center";
        valign = "center";
        rounding = -1;
        outline_thickness = 2;
        outer_color = rgba p.ink;
        inner_color = rgba p.surface;
        font_color = rgba p.bright;
        check_color = rgba p.accent;
        fail_color = rgba p.red;
        capslock_color = rgba p.red;
        fail_text = "";
        placeholder_text = "";
        hide_input = false;
        fade_on_empty = true;
        fade_timeout = 2000;
        dots_size = 0.25;
        dots_spacing = 0.2;
        dots_center = true;
        dots_rounding = -1;
      }];
    };
  };
}
