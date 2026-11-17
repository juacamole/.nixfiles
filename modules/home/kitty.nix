{ ... }:
let
  p = (import ./palette.nix).inkCream;
  # One step darker than the desktop base.
  background = "#15141a";
in {
  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF";
      size = 13;
    };

    keybindings = {
      "shift+ctrl+l" = "next_tab";
      "shift+ctrl+h" = "previous_tab";
      "shift+ctrl+o" = "launch --type=overlay orbitty";
      "shift+ctrl+enter" = "launch --location=split --cwd=current";
      # Plain ctrl+hjkl stays with the shell and with nvim's smart-splits.
      "ctrl+alt+h" = "neighboring_window left";
      "ctrl+alt+j" = "neighboring_window down";
      "ctrl+alt+k" = "neighboring_window up";
      "ctrl+alt+l" = "neighboring_window right";
    };

    settings = {
      shell = "zsh";
      scrollback_lines = 5000;
      enable_audio_bell = "no";
      confirm_os_window_close = 1;
      hide_window_decorations = "yes";
      enabled_layouts = "splits,stack";

      # nvim drives kitty through this socket (smart-splits, <leader>tv/th).
      allow_remote_control = "socket-only";
      listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty-{kitty_pid}";

      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = "yes";

      # Hyprland blurs whatever shows through.
      background_opacity = "0.88";
      background_blur = 0;
      dynamic_background_opacity = "no";

      cursor_shape = "beam";
      cursor_trail = 1;
      cursor = p.yellow;
      cursor_text_color = background;

      inherit background;
      foreground = p.bright;
      selection_background = p.track;
      selection_foreground = p.bright;
      url_color = p.blue;

      color0 = p.raised;
      color1 = p.red;
      color2 = p.green;
      color3 = p.yellow;
      color4 = p.blue;
      color5 = p.magenta;
      color6 = p.cyan;
      color7 = p.text;
      color8 = p.muted;
      color9 = "#f0afa1";
      color10 = "#b4e0b7";
      color11 = "#efd7a3";
      color12 = "#b0c6ea";
      color13 = "#d7bbea";
      color14 = "#b4e0dc";
      color15 = p.bright;

      active_border_color = p.yellow;
      inactive_border_color = p.ink;
      bell_border_color = p.red;

      tab_bar_background = background;
      active_tab_background = p.yellow;
      active_tab_foreground = p.ink;
      inactive_tab_background = p.surface;
      inactive_tab_foreground = p.muted;
    };
  };
}
