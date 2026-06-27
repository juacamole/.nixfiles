{ config, pkgs, ... }:
let
  battery = "BAT1";
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

    # Detect focused/fullscreen window via hyprctl. When user busy in app
    # (any fullscreen mode), suppress floating popup — notification still
    # lands in swaync notification center for later via DnD toggle.
    focused=0
    if command -v hyprctl >/dev/null 2>&1; then
      fs=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.fullscreen // 0' 2>/dev/null || echo 0)
      [ "$fs" != "0" ] && [ "$fs" != "null" ] && focused=1
    fi

    notify() {
      if [ "$focused" = "1" ] && command -v swaync-client >/dev/null 2>&1; then
        # Push silently into notification center, no floating popup.
        was_dnd=$(${pkgs.swaynotificationcenter}/bin/swaync-client --get-dnd 2>/dev/null || echo false)
        ${pkgs.swaynotificationcenter}/bin/swaync-client --dnd-on >/dev/null 2>&1 || true
        ${pkgs.libnotify}/bin/notify-send \
          --app-name=battery \
          --urgency="$1" \
          --icon=battery-caution \
          --hint=string:category:device.battery \
          "$2" "$3"
        sleep 1
        [ "$was_dnd" = "true" ] || ${pkgs.swaynotificationcenter}/bin/swaync-client --dnd-off >/dev/null 2>&1 || true
      else
        ${pkgs.libnotify}/bin/notify-send \
          --app-name=battery \
          --urgency="$1" \
          --icon=battery-caution \
          --hint=string:category:device.battery \
          "$2" "$3"
      fi
    }

    if [ "$capacity" -le ${toString criticalThreshold} ] && [ "$last" != "critical" ]; then
      notify normal "Battery critical" "$capacity% remaining — plug in soon."
      echo critical > "$state_file"
    elif [ "$capacity" -le ${toString lowThreshold} ] && [ "$last" != "low" ] && [ "$last" != "critical" ]; then
      notify low "Battery low" "$capacity% remaining."
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
