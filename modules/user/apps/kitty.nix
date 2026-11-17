{ pkgs, ... }:
let
  # "Ink & cream" set, shared with the quickshell bar / hyprland / hyprlock /
  # starship / nvim. Dark, flat: no blur, no translucency.
  bg = "#15141a";        # a step below base, so the terminal sits darker than the desktop
  bgLight = "#24232c";   # surface
  bgLighter = "#3d3a4f"; # track / selection
  fg = "#ece6d8";        # bright
  fgBright = "#ece6d8";
  fgDim = "#6b6780";     # muted
  ink = "#0f0e13";       # outlines
  accent = "#e6c88a";    # yellow — focus / active / cursor
  black = "#36343f";     # raised
  red = "#e89a8a";
  green = "#9fd3a3";
  yellow = "#e6c88a";
  blue = "#9ab4e0";
  magenta = "#c9a6e0";
  cyan = "#9fd3cf";
  white = "#9b97ad";     # text
  blackBright = "#6b6780";
  redBright = "#f0afa1";
  greenBright = "#b4e0b7";
  yellowBright = "#efd7a3";
  blueBright = "#b0c6ea";
  magentaBright = "#d7bbea";
  cyanBright = "#b4e0dc";
  whiteBright = "#ece6d8";
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF"; # soft rounded mono, see theme.nix
      size = 13;
    };
	keybindings = {
   	  "shift+ctrl+l" = "next_tab";
      "shift+ctrl+h" = "previous_tab";
      "shift+ctrl+o" = "launch --type=overlay orbitty";
      # New split in the current window's cwd (splits layout picks direction).
      "shift+ctrl+enter" = "launch --location=split --cwd=current";
      # ctrl+alt+hjkl: move between kitty windows. Plain ctrl+hjkl stays with
      # the shell (ctrl+l clear etc.); inside nvim, ctrl+hjkl is smart-splits,
      # which hops out to the neighbouring kitty window at the edge.
      "ctrl+alt+h" = "neighboring_window left";
      "ctrl+alt+j" = "neighboring_window down";
      "ctrl+alt+k" = "neighboring_window up";
      "ctrl+alt+l" = "neighboring_window right";
    };
    settings = {
      # Slightly see-through; hyprland blurs what shows behind (settings.nix).
      background_opacity = "0.88";
      background_blur = 0;
      dynamic_background_opacity = "no";
      cursor_shape = "beam";
      cursor_trail = 1;
      cursor = accent;
      cursor_text_color = bg;
      enable_audio_bell = "no";
      hide_window_decorations = "yes";
      confirm_os_window_close = 1;
      scrollback_lines = 5000;
      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = "yes";
      shell = "zsh";
      # Remote control for nvim (smart-splits, <leader>tv/th). socket-only:
      # per-instance socket in the user-private runtime dir.
      allow_remote_control = "socket-only";
      listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty-{kitty_pid}";
      enabled_layouts = "splits,stack";
      background = bg;
      foreground = fg;
      selection_background = bgLighter;
      selection_foreground = fgBright;
      url_color = blue;
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
      active_border_color = accent;
      inactive_border_color = ink;
      bell_border_color = red;
      tab_bar_background = bg;
      active_tab_background = accent;
      active_tab_foreground = ink;
      inactive_tab_background = bgLight;
      inactive_tab_foreground = fgDim;
    };
  };
}
