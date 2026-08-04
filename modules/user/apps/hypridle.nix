{ pkgs, ... }:
# Idle-lock (hyprlock after N minutes idle), toggleable from the Quickshell
# bar. The lock itself is done by hypridle; whether it runs is the toggle.
#
# Design mirrors battery-saver.nix:
#   * hypridle.conf carries the idle `listener`, so a *running* hypridle locks
#     after `idleTimeoutMinutes`.
#   * hypridle is NOT auto-started (no Install.WantedBy) — the daemon running
#     == idle-lock enabled. Default is therefore OFF.
#   * an `idle-lock` script (enable/disable/toggle/status/apply) starts/stops
#     the daemon and records the choice in a state file, so it persists across
#     reboots; the `idle-lock-apply` oneshot re-applies "on" at login.
#   * QS's IdleLock singleton shells out to `idle-lock toggle` / `status`.
let
  idleTimeoutMinutes = 10;

  idleLock = pkgs.writeShellApplication {
    name = "idle-lock";
    # systemctl for the --user start/stop; coreutils for the state file.
    runtimeInputs = with pkgs; [ coreutils systemd ];
    text = ''
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
      STATE_FILE="$STATE_DIR/idle-lock"
      mkdir -p "$STATE_DIR"

      read_state() { if [ -f "$STATE_FILE" ]; then cat "$STATE_FILE"; else echo off; fi; }
      write_state() { printf '%s\n' "$1" > "$STATE_FILE"; }

      start_idle() { systemctl --user start hypridle; }
      stop_idle()  { systemctl --user stop hypridle; }

      case "''${1:-}" in
        enable)  start_idle; write_state on ;;
        disable) stop_idle;  write_state off ;;
        toggle)
          if [ "$(read_state)" = "on" ]; then stop_idle; write_state off;
          else start_idle; write_state on; fi ;;
        status)  read_state ;;
        # Called from the session-start unit; no-op unless state says "on".
        apply)   if [ "$(read_state)" = "on" ]; then start_idle; fi ;;
        *) echo "usage: idle-lock {enable|disable|toggle|status|apply}" >&2; exit 2 ;;
      esac
    '';
  };
in
{
  home.packages = [ pkgs.hypridle idleLock ];

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = ${toString (idleTimeoutMinutes * 60)}
        on-timeout = loginctl lock-session
    }
  '';

  # Defined but intentionally NOT auto-started (no Install section): the unit
  # exists so `idle-lock` can start/stop it, but at login it stays off unless
  # idle-lock-apply turns it on from saved state.
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland's idle daemon (idle-lock)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
  };

  # Re-apply saved idle-lock state on login (starts hypridle iff state == on).
  systemd.user.services.idle-lock-apply = {
    Unit = {
      Description = "Re-apply idle-lock state on session start";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${idleLock}/bin/idle-lock apply";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
