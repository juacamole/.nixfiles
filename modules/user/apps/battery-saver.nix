{ config, pkgs, lib, ... }:
# Battery-saver mode for salz. Owns:
#   * a state file at $XDG_STATE_HOME/quickshell/battery-saver ("on" | "off"),
#   * a `battery-saver` shell script with enable/disable/toggle/status/apply,
#   * a systemd user oneshot that re-applies "on" state on session start.
#
# Actual power-saving lever in v1: force every connected monitor to 60Hz via
# `hyprctl keyword monitor`. Disable path calls `hyprctl reload` to restore
# whatever hyprland/monitors.nix declares — no per-monitor sidecar needed
# because the "before" state is captured by the nix config itself.
#
# The QS Battery widget and Notification action button both shell out to
# `battery-saver toggle`; the singleton then re-reads `battery-saver status`
# to sync its `active` property. State survives QS reload and reboot.
let
  cfg = config.programs.batterySaver;

  batterySaver = pkgs.writeShellApplication {
    name = "battery-saver";
    # hyprctl comes from the running hyprland session's PATH (writeShellApplication
    # prepends its own PATH, keeping the user's).
    runtimeInputs = with pkgs; [ jq coreutils ];
    text = ''
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
      STATE_FILE="$STATE_DIR/battery-saver"
      mkdir -p "$STATE_DIR"

      read_state() {
        if [ -f "$STATE_FILE" ]; then cat "$STATE_FILE"; else echo off; fi
      }

      write_state() {
        printf '%s\n' "$1" > "$STATE_FILE"
      }

      # Force 60 Hz on every connected monitor while preserving current
      # resolution / position / scale. Passing width/height/x/y/scale explicitly
      # avoids hyprland's "preferred" keyword, which won't accept an @refresh
      # override.
      apply_saver() {
        if ! command -v hyprctl >/dev/null 2>&1; then
          echo "battery-saver: hyprctl not on PATH; nothing to apply" >&2
          return 0
        fi
        hyprctl monitors -j \
          | jq -r '.[] | "\(.name),\(.width)x\(.height)@60,\(.x)x\(.y),\(.scale)"' \
          | while IFS= read -r spec; do
              hyprctl keyword monitor "$spec" >/dev/null || true
            done
      }

      # `hyprctl reload` re-parses the nix-generated hyprland config, which
      # restores per-monitor defaults declared in modules/user/apps/hyprland/.
      restore_normal() {
        if ! command -v hyprctl >/dev/null 2>&1; then return 0; fi
        hyprctl reload >/dev/null || true
      }

      cmd="''${1:-}"
      case "$cmd" in
        enable)
          apply_saver
          write_state on
          ;;
        disable)
          restore_normal
          write_state off
          ;;
        toggle)
          if [ "$(read_state)" = "on" ]; then
            restore_normal
            write_state off
          else
            apply_saver
            write_state on
          fi
          ;;
        status)
          read_state
          ;;
        apply)
          # Called from the session-start unit. No-op unless state says "on".
          if [ "$(read_state)" = "on" ]; then
            apply_saver
          fi
          ;;
        *)
          echo "usage: battery-saver {enable|disable|toggle|status|apply}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.programs.batterySaver = {
    enable = lib.mkEnableOption "battery-saver mode" // { default = true; };
    suggestOnLow = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When the battery-warn timer fires at the low threshold and saver mode
        is off, attach a "toggle-saver" action to the notification so the user
        can enable saver by clicking the button in the notification card.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ batterySaver ];

    # Re-apply 60Hz on login if the state file says "on". Without this, a
    # reboot with saver enabled would leave the display at native refresh
    # until the user manually toggled.
    systemd.user.services.battery-saver-apply = {
      Unit = {
        Description = "Re-apply battery saver mode on session start";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${batterySaver}/bin/battery-saver apply";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
