{ pkgs, ... }:
let
  # Saver mode forces every monitor to 60 Hz. The state file is the source of
  # truth; quickshell only calls this script and re-reads `status`.
  batterySaver = pkgs.writeShellApplication {
    name = "battery-saver";
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

      # Explicit mode strings: hyprland's "preferred" takes no @refresh override.
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

      # A reload restores the monitor settings from the generated config.
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
in {
  home.packages = [ batterySaver ];

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
}
