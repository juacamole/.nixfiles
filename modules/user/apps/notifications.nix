{ config, pkgs, ... }:
let
  panelBg = "rgba(58, 42, 24, 0.45)";
  panelBgSolid = "#3a2a18";
  panelBgLight = "#4a3828";
  panelBorder = "rgba(160, 130, 80, 0.3)";
  panelBorderTop = "rgba(190, 165, 115, 0.25)";
  panelBorderBottom = "rgba(30, 20, 10, 0.5)";
  panelShadow = "0 4px 16px rgba(0, 0, 0, 0.4), 0 1px 3px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(200, 176, 120, 0.15), inset 0 -1px 0 rgba(0, 0, 0, 0.2)";
  panelRadius = "6px";

  goldBright = "#dac48a";
  goldMid = "#c8b078";
  goldDim = "#8b7355";
  goldDimAlpha = "rgba(139, 115, 85, 0.4)";
  textShadow = "0 1px 2px rgba(0, 0, 0, 0.5)";

  hoverBg = "rgba(160, 130, 80, 0.12)";
  urgentAccent = "#b87a3d";
in
{
  home.packages = [ pkgs.swaynotificationcenter ];

  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "top";
    cssPriority = "application";
    notification-icon-size = 42;
    notification-body-image-height = 80;
    notification-body-image-width = 200;
    timeout = 6;
    timeout-low = 3;
    timeout-critical = 0;
    fit-to-screen = false;
    control-center-width = 360;
    control-center-height = 560;
    notification-window-width = 360;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 200;
    hide-on-clear = true;
    hide-on-action = true;
    notification-visibility = {};
    widgets = [
      "title"
      "dnd"
      "notifications"
    ];
    widget-config = {
      title = {
        text = "Notifications";
        clear-all-button = true;
        button-text = "Dismiss All";
      };
      dnd = {
        text = "Do Not Disturb";
      };
    };
  };

  xdg.configFile."swaync/style.css".text = ''
    * {
      font-family: "Cinzel", serif;
      font-size: 13px;
      color: ${goldMid};
    }

    .control-center {
      background: ${panelBg};
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: ${panelRadius};
      margin: 8px;
      padding: 12px;
      box-shadow: ${panelShadow};
    }

    .control-center .widget-title {
      color: ${goldBright};
      font-weight: 700;
      font-size: 14px;
      letter-spacing: 2px;
      text-shadow: ${textShadow};
      margin: 4px 8px 8px 8px;
      padding-bottom: 10px;
      border-bottom: 1px solid ${goldDimAlpha};
    }

    .control-center .widget-title > button {
      background: rgba(58, 42, 24, 0.55);
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: 4px;
      color: ${goldMid};
      font-size: 11px;
      letter-spacing: 1px;
      padding: 6px 14px;
      text-shadow: ${textShadow};
      box-shadow: inset 0 1px 0 rgba(200, 176, 120, 0.1), inset 0 -1px 0 rgba(0, 0, 0, 0.15);
    }

    .control-center .widget-title > button:hover {
      background: rgba(180, 155, 105, 0.2);
      color: ${goldBright};
    }

    .widget-dnd {
      font-size: 12px;
      letter-spacing: 0.5px;
      margin: 4px 8px;
      padding: 8px 0;
      border-bottom: 1px solid ${goldDimAlpha};
    }

    .widget-dnd > switch {
      background: rgba(58, 42, 24, 0.55);
      border: 1px solid ${panelBorder};
      border-radius: 12px;
      box-shadow: inset 0 1px 0 rgba(200, 176, 120, 0.08);
    }

    .widget-dnd > switch:checked {
      background: rgba(180, 155, 105, 0.25);
    }

    .widget-dnd > switch slider {
      background: ${goldDim};
      border-radius: 50%;
      min-width: 18px;
      min-height: 18px;
      margin: 2px;
    }

    .widget-dnd > switch:checked slider {
      background: ${goldBright};
    }

    .notification-row {
      outline: none;
      margin: 4px 0;
    }

    .notification-row .notification-background .close-button {
      background: rgba(58, 42, 24, 0.55);
      color: ${goldDim};
      border: 1px solid ${panelBorder};
      border-radius: 50%;
      min-width: 24px;
      min-height: 24px;
      margin: 6px;
      padding: 0;
      box-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
    }

    .notification-row .notification-background .close-button:hover {
      background: rgba(180, 155, 105, 0.25);
      color: ${goldBright};
    }

    .notification {
      background: rgba(58, 42, 24, 0.45);
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: ${panelRadius};
      padding: 0;
      box-shadow: ${panelShadow};
    }

    .notification .notification-content {
      padding: 10px 14px;
    }

    .notification .summary {
      color: ${goldBright};
      font-weight: 700;
      font-size: 13px;
      letter-spacing: 0.5px;
      text-shadow: ${textShadow};
    }

    .notification .body {
      color: ${goldMid};
      font-size: 11px;
    }

    .notification .time {
      color: ${goldDim};
      font-size: 10px;
      letter-spacing: 0.5px;
    }

    .notification .image {
      border-radius: 4px;
      margin: 8px;
      border: 1px solid ${goldDimAlpha};
    }

    .notification.critical {
      border-color: rgba(184, 122, 61, 0.4);
      box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.3),
        0 0 12px rgba(184, 122, 61, 0.12),
        inset 0 1px 0 rgba(200, 176, 120, 0.1);
    }

    .notification.critical .summary {
      color: ${urgentAccent};
    }

    .notification .notification-action {
      background: rgba(58, 42, 24, 0.55);
      border: 1px solid ${panelBorder};
      border-top: 1px solid ${panelBorderTop};
      border-bottom: 1px solid ${panelBorderBottom};
      border-radius: 4px;
      color: ${goldMid};
      font-size: 11px;
      letter-spacing: 1px;
      padding: 6px 12px;
      margin: 4px 2px;
      box-shadow: inset 0 1px 0 rgba(200, 176, 120, 0.08);
    }

    .notification .notification-action:hover {
      background: rgba(180, 155, 105, 0.2);
      color: ${goldBright};
    }

    .notification-group {
      margin: 2px 0;
    }

    .notification-group .notification-group-headers {
      color: ${goldDim};
      font-size: 11px;
      letter-spacing: 1px;
      padding: 4px 8px;
    }

    .floating-notifications {
      background: transparent;
    }

    .floating-notifications .notification {
      box-shadow:
        0 4px 16px rgba(0, 0, 0, 0.45),
        0 1px 4px rgba(0, 0, 0, 0.3),
        inset 0 1px 0 rgba(200, 176, 120, 0.12),
        inset 0 -1px 0 rgba(0, 0, 0, 0.15);
    }
  '';
}
