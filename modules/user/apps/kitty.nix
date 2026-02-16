{ pkgs, ... }: {
  programs.kitty = {
    enable = true;
    font = {

      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      background_opacity = "0.85";
      
      background_blur = 20;
      dynamic_background_opacity = "yes";
      cursor_shape = "beam";
      cursor_trail = 1;
      enable_audio_bell = "no";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;

      scrollback_lines = 5000;

      repaint_delay = 10;
      input_delay = 1;
      sync_to_monitor = "yes";

      shell = "zsh";
    };
    themeFile = "gruvbox-dark-soft"; 
  };
}
