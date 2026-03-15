{ config, pkgs, ... }:
let
  panelBg = "rgba(58, 42, 24, 0.75)";
  panelBorder = "rgba(160, 130, 80, 0.3)";
  panelBorderTop = "rgba(190, 165, 115, 0.25)";
  panelBorderBottom = "rgba(30, 20, 10, 0.5)";
  panelRadius = "8";

  goldBright = "rgba(218, 196, 138, 1.0)";
  goldMid = "rgba(200, 176, 120, 1.0)";
  goldDim = "rgba(139, 115, 85, 1.0)";
  goldDimAlpha = "rgba(139, 115, 85, 0.4)";

  inputBg = "rgba(58, 42, 24, 0.65)";
  inputBorderFocus = "rgba(218, 196, 138, 0.5)";
  failColor = "rgba(184, 122, 61, 1.0)";
  checkColor = "rgba(180, 155, 105, 0.6)";
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
          path = "~/Pictures/wallpapers/parchment.png";
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
          color = goldBright;
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
          color = goldDim;
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
          outline_thickness = 1;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          dots_rounding = -1;
          outer_color = goldDimAlpha;
          inner_color = inputBg;
          font_color = goldMid;
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "";
          hide_input = false;
          rounding = 6;
          check_color = checkColor;
          fail_color = failColor;
          fail_text = "";
          capslock_color = failColor;
          position = "0, 30";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 6;
          shadow_color = "rgba(0, 0, 0, 0.35)";
          shadow_boost = 1.0;
        }
      ];
    };
  };
}
