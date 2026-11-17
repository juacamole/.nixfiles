{ config, pkgs, ... }:
let
  # Wallpaper palette (stormy night-blue), shared with quickshell Theme.qml.
  # Flat: opaque surface, hard ink outline, no soft drop shadows.
  bright = "rgba(232, 238, 242, 1.0)";  # #e8eef2 — emphasised text (mask white)
  text = "rgba(143, 166, 191, 1.0)";    # #8fa6bf — normal UI text
  ink = "rgba(8, 12, 18, 1.0)";         # #080c12 — outlines

  inputBg = "rgba(26, 37, 51, 1.0)";    # #1a2533 — surface
  failColor = "rgba(224, 148, 138, 1.0)";   # #e0948a red (bar's crit)
  checkColor = "rgba(174, 188, 240, 1.0)";  # #aebcf0 periwinkle (bar's accent)
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        grace = 0;
        no_fade_in = false;
        no_fade_out = false;
      };

      background = [
        {
          monitor = "";
          path = "~/Pictures/wallpaper/wallpaper.png";
          blur_passes = 4;
          blur_size = 6;
          brightness = 0.7;
          vibrancy = 0.1;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = bright;
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
          color = text;
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

      input-field = [
        {
          monitor = "";
          size = "280, 44";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          dots_rounding = -1;
          outer_color = ink;
          inner_color = inputBg;
          font_color = bright;
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "";
          hide_input = false;
          rounding = -1; # full pill, like the bar
          check_color = checkColor;
          fail_color = failColor;
          fail_text = "";
          capslock_color = failColor;
          position = "0, 30";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
