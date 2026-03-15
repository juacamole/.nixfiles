{ pkgs, ... }:
let
  bg = "#1e1b16";
  bgLight = "#2a2620";
  bgLighter = "#36312a";
  fg = "#d4c4a0";
  fgBright = "#e8dcc8";
  fgDim = "#9e8e70";
  black = "#14120e";
  red = "#c45a4a";
  green = "#8aad6a";
  yellow = "#d4a843";
  blue = "#6a8fa0";
  magenta = "#a07090";
  cyan = "#6a9a8a";
  white = "#d4c4a0";
  blackBright = "#4a4238";
  redBright = "#d87060";
  greenBright = "#a0c480";
  yellowBright = "#e0c060";
  blueBright = "#80a8b8";
  magentaBright = "#b888a0";
  cyanBright = "#80b0a0";
  whiteBright = "#e8dcc8";
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      background_opacity = "0.82";
      background_blur = 24;
      dynamic_background_opacity = "yes";
      cursor_shape = "beam";
      cursor_trail = 1;
      cursor = fgBright;
      cursor_text_color = bg;
      enable_audio_bell = "no";
      hide_window_decorations = "yes";
      confirm_os_window_close = 1;
      scrollback_lines = 5000;
      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = "yes";
      shell = "zsh";
      background = bg;
      foreground = fg;
      selection_background = bgLighter;
      selection_foreground = fgBright;
      url_color = yellow;
      color0 = black;
      color1 = red;
      color2 = green;
      color3 = yellow;
      color4 = blue;
      color5 = magenta;
      color6 = cyan;
      color7 = white;
      color8 = blackBright;
      color9 = redBright;
      color10 = greenBright;
      color11 = yellowBright;
      color12 = blueBright;
      color13 = magentaBright;
      color14 = cyanBright;
      color15 = whiteBright;
      active_border_color = fgDim;
      inactive_border_color = bgLighter;
      bell_border_color = red;
      tab_bar_background = black;
      active_tab_background = bgLight;
      active_tab_foreground = fgBright;
      inactive_tab_background = black;
      inactive_tab_foreground = fgDim;
    };
  };
}
