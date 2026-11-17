{ config, pkgs, hostKind, ... }:
let
  # Asahi exposes the Mac battery as "macsmc-battery".
  battery = if hostKind == "mac" then "macsmc-battery" else "BAT1";
  lowThreshold = 20;
  criticalThreshold = 10;
  emptyThreshold = 5;

  checkScript = pkgs.writeShellScript "battery-warn" ''
    set -eu
    gdbus=${pkgs.glib.bin}/bin/gdbus

    BAT=/sys/class/power_supply/${battery}
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

    # Close the previous warning toast, if any. Closing + re-sending instead of
    # replaces_id: QS updates replaced notifications in place without re-popping.
    close_prev() {
      [ "$id" = "0" ] && return 0
      $gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification "$id" \
        >/dev/null 2>&1 || true
      echo 0 > "$id_file"
    }

    # Plugged in: reset, and close any warning still on screen (critical ones
    # don't auto-expire).
    if [ "$status" != "Discharging" ]; then
      close_prev
      echo ok > "$state_file"
      exit 0
    fi

    # Fullscreen (likely gaming): hold back the *low* toast without recording
    # it, so it fires once fullscreen ends. Critical always gets through.
    fullscreen=0
    if command -v hyprctl >/dev/null 2>&1; then
      fs=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.fullscreen // 0' 2>/dev/null || echo 0)
      [ "$fs" != "0" ] && [ "$fs" != "null" ] && [ "$fs" != "false" ] && fullscreen=1
    fi

    # Sent over gdbus rather than notify-send: notify-send with --action blocks
    # until the toast closes, and critical toasts never auto-close, so the
    # oneshot would hang and swallow every later warning.
    # $1 = urgency byte (1 normal, 2 critical), $2 = summary, $3 = body.
    notify() {
      actions="[]"
      # Offer saver from the toast when it's off. The QS card handles the
      # "toggle-saver" identifier locally, so nobody needs to listen for it.
      if command -v battery-saver >/dev/null 2>&1 \
         && [ "$(battery-saver status 2>/dev/null)" = "off" ]; then
        actions="['toggle-saver', 'Enable battery saver']"
      fi
      # Each level replaces the previous toast instead of stacking.
      close_prev
      reply=$($gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        battery 0 battery-caution "$2" "$3" "$actions" \
        "{'urgency': <byte $1>, 'category': <'device.battery'>}" "int32 -1")
      # reply looks like "(uint32 42,)"
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
in
{
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
}
