{ config, pkgs, ... }:
let
  panelBg = "rgba(58, 42, 24, 0.75)";
  panelBorder = "rgba(160, 130, 80, 0.3)";
  panelBorderTop = "rgba(190, 165, 115, 0.25)";
  panelBorderBottom = "rgba(30, 20, 10, 0.5)";
  panelShadow = "0 2px 10px rgba(0, 0, 0, 0.35), 0 1px 3px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(200, 176, 120, 0.15), inset 0 -1px 0 rgba(0, 0, 0, 0.2)";
  panelRadius = "6px";

  goldBright = "#dac48a";
  goldMid = "#c8b078";
  goldDim = "rgba(180, 155, 105, 0.25)";
  goldVisible = "rgba(200, 176, 120, 0.5)";
  goldHover = "rgba(200, 176, 120, 0.75)";
  goldGlow = "0 0 10px rgba(200, 176, 120, 0.2), 0 1px 2px rgba(0, 0, 0, 0.5)";
  textShadow = "0 1px 2px rgba(0, 0, 0, 0.5)";

  activeGradient = "linear-gradient(to bottom, rgba(180, 155, 105, 0.3), rgba(100, 75, 40, 0.25))";
  activeBorder = "rgba(180, 155, 105, 0.25)";
  activeBorderTop = "rgba(210, 190, 140, 0.35)";
  activeBorderBottom = "rgba(40, 30, 15, 0.5)";

  barMarginTop = "8";
  barMarginSide = "12";
  barHeight = "34";
in
{
  home.packages = [ pkgs.waybar ];

  xdg.configFile."waybar/clock-exec.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      STATE_FILE="/tmp/waybar-clock-state"
      if [ -f "$STATE_FILE" ]; then
        date '+%A, %d %B %Y'
      else
        date '+%H:%M'
      fi
    '';
  };

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "top",
      "height": ${barHeight},
      "margin-top": ${barMarginTop},
      "margin-left": ${barMarginSide},
      "margin-right": ${barMarginSide},
      "modules-left": ["hyprland/workspaces"],
      "modules-center": ["custom/clock"],
      "modules-right": ["battery", "custom/net"],
      "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
          "1": "Ⅰ",
          "2": "Ⅱ",
          "3": "Ⅲ",
          "4": "Ⅳ",
          "5": "Ⅴ",
          "6": "Ⅵ",
          "7": "Ⅶ",
          "8": "Ⅷ",
          "9": "Ⅸ",
          "10": "Ⅹ"
        },
        "persistent-workspaces": {
          "*": 10
        }
      },
      "custom/clock": {
        "exec": "~/.config/waybar/clock-exec.sh",
        "interval": 1,
        "on-click": "if [ -f /tmp/waybar-clock-state ]; then rm /tmp/waybar-clock-state; else touch /tmp/waybar-clock-state; fi",
        "tooltip": false
      },
      "battery": {
        "format": "{capacity}%",
        "interval": 30,
        "tooltip": false
      },
      "custom/net": {
        "exec": "if grep -q up /sys/class/net/wl*/operstate 2>/dev/null; then echo 'Wi-Fi'; elif grep -q up /sys/class/net/e*/operstate 2>/dev/null; then echo 'Eth'; else echo '—'; fi",
        "interval": 5,
        "tooltip": false
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * {
      all: unset;
      font-family: "Cinzel", serif;
      font-size: 13px;
    }

    window#waybar {
      background: transparent;
    }

    #workspaces {
      background: ${panelBg};
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: ${panelRadius};
      padding: 0 6px;
      margin: 4px 0;
      box-shadow: ${panelShadow};
    }

    #workspaces button {
      padding: 0 7px;
      margin: 3px 1px;
      border-radius: 3px;
      color: ${goldDim};
      font-size: 11px;
      letter-spacing: 1px;
      transition: 200ms ease;
    }

    #workspaces button.visible {
      color: ${goldVisible};
    }

    #workspaces button.active {
      color: ${goldBright};
      background: ${activeGradient};
      border: 1px solid ${activeBorder};
      border-top-color: ${activeBorderTop};
      border-bottom-color: ${activeBorderBottom};
      box-shadow: inset 0 1px 0 rgba(220, 195, 140, 0.15), 0 0 8px rgba(180, 155, 105, 0.1);
      font-weight: 700;
      text-shadow: 0 0 8px rgba(200, 176, 120, 0.25), ${textShadow};
    }

    #workspaces button:hover {
      color: ${goldHover};
      background: rgba(160, 130, 80, 0.15);
    }

    #custom-clock {
      background: ${panelBg};
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: ${panelRadius};
      padding: 0 22px;
      margin: 4px 0;
      font-size: 14px;
      letter-spacing: 2px;
      font-weight: 600;
      color: ${goldBright};
      text-shadow: ${goldGlow};
      box-shadow: ${panelShadow};
    }

    #battery {
      background: ${panelBg};
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: ${panelRadius} 0 0 ${panelRadius};
      padding: 0 12px;
      margin: 4px 0;
      margin-right: 0;
      font-size: 12px;
      letter-spacing: 0.5px;
      font-weight: 500;
      color: ${goldMid};
      text-shadow: ${textShadow};
      box-shadow: ${panelShadow};
      border-right: none;
    }

    #custom-net {
      background: ${panelBg};
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: 0 ${panelRadius} ${panelRadius} 0;
      padding: 0 12px;
      margin: 4px 0;
      margin-right: 4px;
      font-size: 12px;
      letter-spacing: 0.5px;
      font-weight: 500;
      color: ${goldMid};
      text-shadow: ${textShadow};
      box-shadow: ${panelShadow};
      border-left: 1px solid rgba(100, 75, 40, 0.3);
    }
  '';
}
