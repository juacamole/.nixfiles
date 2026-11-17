{ pkgs, username, ... }:

# Steam on Asahi: a muvm microVM with FEX for x86 translation. Every
# workaround below fixes a failure that was reproduced; see docs/steam-muvm.md
# before removing one.
let
  # Stands in for pressure-vessel's entry point to give steamwebhelper
  # --single-process. Steam's own scripts are checksum-verified, so they
  # cannot be patched instead.
  webhelperEntryPoint = pkgs.writeTextFile {
    name = "steam-webhelper-entry-point";
    executable = true;
    destination = "/_v2-entry-point";
    text = ''
      #!${pkgs.bash}/bin/bash
      REAL="$HOME/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/_v2-entry-point"

      if [ ! -x "$REAL" ]; then
        echo "steam-webhelper-entry-point: $REAL missing, cannot delegate" >&2
        exit 1
      fi

      # argv: -- <steamwebhelper_sniper_wrap.sh> <webhelper args...>
      args=()
      inserted=
      for a in "$@"; do
        args+=( "$a" )
        if [ -z "$inserted" ] && [[ "$a" == *steamwebhelper_sniper_wrap.sh ]]; then
          args+=( --single-process )
          inserted=1
        fi
      done
      [ -n "$inserted" ] || args=( "$@" )

      exec "$REAL" "''${args[@]}"
    '';
  };

  steam-muvm = pkgs.writeShellApplication {
    name = "steam-muvm";
    # bubblewrap: steam.sh's requirements check looks for bwrap on PATH.
    runtimeInputs = [ pkgs.muvm pkgs.fex pkgs.coreutils pkgs.bubblewrap ];
    text = ''
      set -euo pipefail

      STEAM_DIR="''${HOME}/.local/share/Steam"
      STEAM_SH="''${STEAM_DIR}/steam.sh"
      FEX_ROOTFS_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/fex-emu/RootFS"

      # Prefer an extracted rootfs: FUSE mounts are unreliable inside the guest.
      shopt -s nullglob
      dirs=( "''${FEX_ROOTFS_DIR}"/*/ )
      files=( "''${FEX_ROOTFS_DIR}"/*.sqsh "''${FEX_ROOTFS_DIR}"/*.erofs )
      if [ ''${#dirs[@]} -gt 0 ]; then
        export FEX_ROOTFS="''${dirs[0]%/}"
      elif [ ''${#files[@]} -gt 0 ]; then
        export FEX_ROOTFS="''${files[0]}"
      else
        cat >&2 <<EOF
      No FEX rootfs found in ''${FEX_ROOTFS_DIR}.
      Install + extract once with:
          FEXRootFSFetcher -y -x --distro-name=Ubuntu --distro-version=24_04
          unsquashfs -d ''${FEX_ROOTFS_DIR}/Ubuntu_24_04 \\
                     ''${FEX_ROOTFS_DIR}/Ubuntu_24_04.sqsh
      EOF
        exit 1
      fi

      if [ ! -x "''${STEAM_SH}" ]; then
        cat >&2 <<EOF
      Steam not installed at ''${STEAM_SH}.
      Bootstrap it once with:
          mkdir -p ''${STEAM_DIR}
          curl -L https://repo.steampowered.com/steam/archive/precise/steam_latest.tar.gz \\
            | tar -xz -C ''${STEAM_DIR} --strip-components=1
      The first launch will pull the full Steam runtime; expect ~5 GB.
      EOF
        exit 1
      fi

      # srt-logger hangs in the guest waiting for a handshake.
      export STEAM_RUNTIME_LOGGER=0
      # Skips steam.sh's host `ldd` preflight, which cannot work here.
      export STEAMOS=1
      # Only the Asahi driver; Steam otherwise sometimes picks llvmpipe.
      export VK_LOADER_DRIVERS_SELECT='*asahi*'
      # Steam's Vulkan layers crash on the Asahi driver.
      export DISABLE_VK_LAYER_VALVE_steam_fossilize_64=1
      export DISABLE_VK_LAYER_VALVE_steam_fossilize_32=1
      export DISABLE_VK_LAYER_VALVE_steam_overlay_64=1
      export DISABLE_VK_LAYER_VALVE_steam_overlay_32=1
      # Native bwrap: Steam's x86 srt-bwrap hangs under FEX.
      export PRESSURE_VESSEL_BWRAP=${pkgs.bubblewrap}/bin/bwrap
      export STEAM_RUNTIME_STEAMRT=${webhelperEntryPoint}

      ulimit -c unlimited || true

      # muvm aborts on `-e VAR` when VAR is unset, so forward only what is set.
      env_args=()
      for v in FEX_ROOTFS STEAM_RUNTIME_LOGGER STEAMOS \
               WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE \
               XDG_RUNTIME_DIR XDG_DATA_DIRS \
               XCURSOR_THEME XCURSOR_SIZE \
               HYPRCURSOR_THEME HYPRCURSOR_SIZE \
               VK_LOADER_DRIVERS_SELECT PRESSURE_VESSEL_BWRAP \
               STEAM_RUNTIME_STEAMRT \
               DISABLE_VK_LAYER_VALVE_steam_fossilize_64 \
               DISABLE_VK_LAYER_VALVE_steam_fossilize_32 \
               DISABLE_VK_LAYER_VALVE_steam_overlay_64 \
               DISABLE_VK_LAYER_VALVE_steam_overlay_32; do
        if [ -n "''${!v-}" ]; then
          env_args+=( -e "$v" )
        fi
      done

      # The `--` is required, or muvm parses Steam's flags as its own.
      exec muvm "''${env_args[@]}" \
        -- "''${STEAM_SH}" -no-cef-sandbox -cef-disable-d3d11 \
           -forcedesktopscaling=2.0 "$@"
    '';
  };

  steam-muvm-desktop = pkgs.makeDesktopItem {
    name = "steam-muvm";
    desktopName = "Steam";
    comment = "Steam via muvm + FEX (Asahi)";
    icon = "/home/${username}/.local/share/Steam/icons/256/steam.png";
    exec = "${steam-muvm}/bin/steam-muvm %U";
    terminal = false;
    type = "Application";
    categories = [ "Game" "Network" ];
    mimeTypes = [ "x-scheme-handler/steam" ];
    startupNotify = true;
  };
in {
  environment.systemPackages = [
    pkgs.muvm
    pkgs.fex
    pkgs.passt
    pkgs.squashfsTools
    steam-muvm
    steam-muvm-desktop
  ];

  # muvm needs /dev/kvm.
  users.users.${username}.extraGroups = [ "kvm" ];

  # Steam Runtime scripts use #!/bin/bash, and pressure-vessel binds /usr/lib.
  # The guest sees both through virtiofs.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    "d /usr 0755 root root - -"
    "d /usr/lib 0755 root root - -"
  ];
}
