{ pkgs, ... }:
let
  idleTimeoutMinutes = 10;

  # Idle-lock is the bar's coffee toggle. On: hypridle runs and locks after
  # the timeout, and the lid suspends. Off: hypridle is stopped and lid-awake
  # holds a lid-switch inhibitor. The state file persists the choice.
  idleLock = pkgs.writeShellApplication {
    name = "idle-lock";
    runtimeInputs = with pkgs; [ coreutils systemd ];
    text = ''
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
      STATE_FILE="$STATE_DIR/idle-lock"
      mkdir -p "$STATE_DIR"

      read_state() { if [ -f "$STATE_FILE" ]; then cat "$STATE_FILE"; else echo off; fi; }
      write_state() { printf '%s\n' "$1" > "$STATE_FILE"; }

      start_idle() { systemctl --user stop lid-awake; systemctl --user start hypridle; }
      stop_idle()  { systemctl --user stop hypridle; systemctl --user start lid-awake; }

      case "''${1:-}" in
        enable)  start_idle; write_state on ;;
        disable) stop_idle;  write_state off ;;
        toggle)
          if [ "$(read_state)" = "on" ]; then stop_idle; write_state off;
          else start_idle; write_state on; fi ;;
        status)  read_state ;;
        apply)   if [ "$(read_state)" = "on" ]; then start_idle; else stop_idle; fi ;;
        *) echo "usage: idle-lock {enable|disable|toggle|status|apply}" >&2; exit 2 ;;
      esac
    '';
  };

  sessionUnit = description: {
    Description = description;
    After = [ "graphical-session.target" ];
    PartOf = [ "graphical-session.target" ];
  };
in {
  home.packages = [ pkgs.hypridle idleLock ];

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = ${toString (idleTimeoutMinutes * 60)}
        on-timeout = loginctl lock-session
    }
  '';

  # hypridle and lid-awake have no Install section on purpose: only
  # `idle-lock` starts them.
  systemd.user.services.hypridle = {
    Unit = sessionUnit "Hyprland's idle daemon (idle-lock)";
    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
  };

  systemd.user.services.lid-awake = {
    Unit = sessionUnit "Ignore lid close while idle-lock is off";
    Service.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=handle-lid-switch --who=idle-lock --why=idle-lock-off --mode=block ${pkgs.coreutils}/bin/sleep infinity";
  };

  systemd.user.services.idle-lock-apply = {
    Unit = sessionUnit "Re-apply idle-lock state on session start";
    Service = {
      Type = "oneshot";
      ExecStart = "${idleLock}/bin/idle-lock apply";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
