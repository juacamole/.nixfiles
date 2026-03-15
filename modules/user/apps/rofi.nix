{ pkgs, config, ... }:
let
  panelBg = "rgba(58, 42, 24, 0.85)";
  panelBgSolid = "#3a2a18";
  panelBgSelected = "#4a3828";
  panelBorder = "rgba(160, 130, 80, 0.3)";
  goldBright = "#dac48a";
  goldMid = "#c8b078";
  goldDim = "#8b7355";
  textShadow = "0 1px 2px rgba(0, 0, 0, 0.5)";
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    extraConfig = {
      modi = "drun";
      show-icons = true;
      drun-display-format = "{name}";
      font = "Cinzel 12";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg = mkLiteral "${panelBgSolid}";
        fg = mkLiteral "${goldMid}";
        accent = mkLiteral "${goldBright}";
        bg-selected = mkLiteral "${panelBgSelected}";
        dim = mkLiteral "${goldDim}";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };
      "window" = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        fullscreen = mkLiteral "false";
        width = mkLiteral "550px";
        x-offset = mkLiteral "0px";
        y-offset = mkLiteral "0px";
        enabled = mkLiteral "true";
        border = mkLiteral "1px";
        border-radius = mkLiteral "8px";
        border-color = mkLiteral "@dim";
        background-color = mkLiteral "@bg";
        cursor = mkLiteral "default";
      };
      "mainbox" = {
        padding = mkLiteral "24px";
        children = mkLiteral ''[ "inputbar", "listview" ]'';
        background-color = mkLiteral "@bg";
      };
      "inputbar" = {
        margin = mkLiteral "0px 0px 16px 0px";
        padding = mkLiteral "0px";
        children = mkLiteral ''[ "prompt", "entry" ]'';
        background-color = mkLiteral "transparent";
        border = mkLiteral "0px 0px 1px 0px";
        border-color = mkLiteral "@dim";
      };
      "prompt" = {
        padding = mkLiteral "10px 14px";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@accent";
        font = mkLiteral "\"Cinzel Bold 12\"";
      };
      "entry" = {
        padding = mkLiteral "10px";
        text-color = mkLiteral "@fg";
        placeholder = mkLiteral "\"Search...\"";
        placeholder-color = mkLiteral "@dim";
        background-color = mkLiteral "transparent";
      };
      "listview" = {
        columns = 1;
        lines = 8;
        fixed-height = true;
        spacing = mkLiteral "4px";
        background-color = mkLiteral "transparent";
      };
      "element" = {
        padding = mkLiteral "10px 12px";
        border-radius = mkLiteral "4px";
        background-color = mkLiteral "transparent";
      };
      "element selected" = {
        background-color = mkLiteral "@bg-selected";
        text-color = mkLiteral "@accent";
        border = mkLiteral "1px";
        border-color = mkLiteral "rgba(160, 130, 80, 0.2)";
        border-radius = mkLiteral "4px";
      };
      "element-icon" = {
        size = mkLiteral "22px";
        cursor = mkLiteral "inherit";
        margin = mkLiteral "0px 10px 0px 0px";
      };
      "element-text" = {
        vertical-align = mkLiteral "0.5";
        cursor = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };
    };
  };
}
