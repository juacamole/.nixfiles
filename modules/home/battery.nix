{ config, lib, pkgs, ... }:
let
  cfg = config.services.battery-warn;
  lowThreshold = 20;
  criticalThreshold = 10;
  emptyThreshold = 5;

  checkScript = pkgs.writeShellScript "battery-warn" ''
    set -eu
    gdbus=${pkgs.glib.bin}/bin/gdbus

    BAT=/sys/class/power_supply/${cfg.device}
    [ -d "$BAT" ] || exit 0

    capacity=$(cat "$BAT/capacity")
    status=$(cat "$BAT/status")

    state_dir="''${XDG_RUNTIME_DIR:-/tmp}/battery-warn"
    mkdir -p "$state_dir"
    state_file="$state_dir/last"
    id_file="$state_dir/id"
    last=""
    [ -f "$state_file" ] && last=$(cat "$state_file")
    id=0
    [ -f "$id_file" ] && id=$(cat "$id_file")

    # Close and re-send rather than replaces_id: quickshell updates a
    # replaced notification in place without popping it again.
    close_prev() {
      [ "$id" = "0" ] && return 0
      $gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification "$id" \
        >/dev/null 2>&1 || true
      echo 0 > "$id_file"
    }

    if [ "$status" != "Discharging" ]; then
      close_prev
      echo ok > "$state_file"
      exit 0
    fi

    # In fullscreen the low warning waits; critical always gets through.
    fullscreen=0
    if command -v hyprctl >/dev/null 2>&1; then
      fs=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.fullscreen // 0' 2>/dev/null || echo 0)
      [ "$fs" != "0" ] && [ "$fs" != "null" ] && [ "$fs" != "false" ] && fullscreen=1
    fi

    # gdbus, not notify-send: with --action that blocks until the toast
    # closes, and critical toasts never close on their own.
    # $1 = urgency byte (1 normal, 2 critical), $2 = summary, $3 = body.
    notify() {
      actions="[]"
      if command -v battery-saver >/dev/null 2>&1 \
         && [ "$(battery-saver status 2>/dev/null)" = "off" ]; then
        actions="['toggle-saver', 'Enable battery saver']"
      fi
      close_prev
      reply=$($gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        battery 0 battery-caution "$2" "$3" "$actions" \
        "{'urgency': <byte $1>, 'category': <'device.battery'>}" "int32 -1")
      new_id=$(echo "$reply" | sed -n 's/.*uint32 \([0-9]*\).*/\1/p')
      echo "''${new_id:-0}" > "$id_file"
    }

    if [ "$capacity" -le ${toString emptyThreshold} ] && [ "$last" != "empty" ]; then
      notify 2 "Battery almost empty" "$capacity% left — plug in now or save your work."
      echo empty > "$state_file"
    elif [ "$capacity" -le ${toString criticalThreshold} ] && [ "$last" != "critical" ] && [ "$last" != "empty" ]; then
      notify 2 "Battery critical" "$capacity% left — plug in soon."
      echo critical > "$state_file"
    elif [ "$capacity" -le ${toString lowThreshold} ] && [ "$last" = "ok" -o -z "$last" ] && [ "$fullscreen" = "0" ]; then
      notify 1 "Battery low" "$capacity% left."
      echo low > "$state_file"
    fi
  '';
in {
  options.services.battery-warn = {
    device = lib.mkOption {
      type = lib.types.str;
      default = "BAT1";
      description = "Battery name under /sys/class/power_supply.";
    };
  };

  config = {
    systemd.user.services.battery-warn = {
      Unit.Description = "Battery low warning notification";
      Service = {
        Type = "oneshot";
        ExecStart = "${checkScript}";
      };
    };

    systemd.user.timers.battery-warn = {
      Unit.Description = "Periodic battery check";
      Timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
        AccuracySec = "15s";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
