{ config, pkgs, hostKind, ... }:
let
  # TODO(salz): confirm the Mac battery name from /sys/class/power_supply
  # (Asahi commonly exposes "macsmc-battery").
  battery = if hostKind == "mac" then "macsmc-battery" else "BAT1";
  lowThreshold = 20;
  criticalThreshold = 10;

  checkScript = pkgs.writeShellScript "battery-warn" ''
    set -eu

    BAT=/sys/class/power_supply/${battery}
    [ -d "$BAT" ] || exit 0

    capacity=$(cat "$BAT/capacity")
    status=$(cat "$BAT/status")

    state_dir="''${XDG_RUNTIME_DIR:-/tmp}/battery-warn"
    mkdir -p "$state_dir"
    state_file="$state_dir/last"
    last=""
    [ -f "$state_file" ] && last=$(cat "$state_file")

    # Reset state when charging.
    if [ "$status" != "Discharging" ]; then
      echo "ok" > "$state_file"
      exit 0
    fi

    # Detect focused/fullscreen window via hyprctl. When the user is in a
    # fullscreen app (likely gaming), skip the toast — the QS notification
    # center will still hold the missed message via its history.
    focused=0
    if command -v hyprctl >/dev/null 2>&1; then
      fs=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.fullscreen // 0' 2>/dev/null || echo 0)
      [ "$fs" != "0" ] && [ "$fs" != "null" ] && focused=1
    fi

    # If battery-saver mode is installed and currently off, we attach a
    # "toggle-saver" action to the low notification so the user can enable
    # saver directly from the toast. The QS Notifications card renders the
    # action button and handles the click locally (Quickshell.Io Process),
    # so it doesn't matter that notify-send exits before the DBus
    # ActionInvoked round-trip.
    extra_args=()
    if command -v battery-saver >/dev/null 2>&1 \
       && [ "$(battery-saver status 2>/dev/null)" = "off" ]; then
      extra_args+=("--action=toggle-saver=Enable battery saver")
    fi

    notify() {
      [ "$focused" = "1" ] && return 0
      ${pkgs.libnotify}/bin/notify-send \
        --app-name=battery \
        --urgency="$1" \
        --icon=battery-caution \
        --hint=string:category:device.battery \
        "''${extra_args[@]-}" \
        "$2" "$3"
    }

    if [ "$capacity" -le ${toString criticalThreshold} ] && [ "$last" != "critical" ]; then
      notify normal "Battery critical" "$capacity% remaining — plug in soon."
      echo critical > "$state_file"
    elif [ "$capacity" -le ${toString lowThreshold} ] && [ "$last" != "low" ] && [ "$last" != "critical" ]; then
      notify low "Battery low" "$capacity% remaining. Enable saver?"
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
