{ pkgs, config, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    
    extraConfig = {
      modi = "drun";
      show-icons = true;
      drun-display-format = "{name}";
      font = "JetBrainsMono Nerd Font 11";
    };

    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg = mkLiteral "#1e1e2e";
        fg = mkLiteral "#cdd6f4";
        accent = mkLiteral "#cba6f7";
        bg-selected = mkLiteral "#313244";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };

      "window" = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        fullscreen = mkLiteral "false";
        width = mkLiteral "600px";
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";

        enabled = mkLiteral "true";
        border = mkLiteral "2px";
        border-radius = mkLiteral "12px";
        border-color = mkLiteral "@accent";
        background-color = mkLiteral "@bg";
        cursor = mkLiteral "default";
      };

      "mainbox" = {
        padding = mkLiteral "20px";
        children = mkLiteral "[ \"inputbar\", \"listview\" ]";
      };

      "inputbar" = {
        margin = mkLiteral "0px 0px 20px 0px";
        children = mkLiteral "[ \"prompt\", \"entry\" ]";
      };

      "prompt" = {
        padding = mkLiteral "10px";
        background-color = mkLiteral "@accent";
        text-color = mkLiteral "@bg";
        border-radius = mkLiteral "8px";
      };

      "entry" = {
        padding = mkLiteral "10px";
        placeholder = mkLiteral "\"Search apps...\"";
        placeholder-color = mkLiteral "@fg";
      };

      "listview" = {
        columns = 1;
        lines = 8;
        fixed-height = true;
      };

      "element" = {
        padding = mkLiteral "8px";
        border-radius = mkLiteral "8px";
      };

      "element selected" = {
        background-color = mkLiteral "@bg-selected";
        text-color = mkLiteral "@accent";
      };

      "element-icon" = {
        size = mkLiteral "24px";
        cursor = mkLiteral "inherit";
      };

      "element-text" = {
        vertical-align = mkLiteral "0.5";
        cursor = mkLiteral "inherit";
      };
    };
  };
}
