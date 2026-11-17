{ config, pkgs, lib, username, ... }:

# Steam on Asahi via muvm.
#
# muvm boots a libkrun microVM that mounts the host rootfs over virtiofs,
# bridges Wayland/X11/PipeWire/HID to the host, and uses DRM native context
# to pass the Asahi GPU through. FEX-Emu provides x86_64 -> aarch64
# translation inside the guest via binfmt_misc set up by muvm-guest.
#
# Two pieces cannot be Nixified because they're large runtime blobs the
# user must accept Valve/FEX licensing for:
#   1. FEX rootfs (an x86_64 distro squashfs)
#   2. The Steam x86_64 portable install
# The `steam-muvm` wrapper prints the exact commands to run once if either
# is missing.
#
# HISTORY: this module used to ship an `srt-bwrap` shim — a size-padded
# aarch64 ELF copied over all ~22 pressure-vessel srt-bwrap binaries, plus
# a 3s watcher re-applying it whenever Steam's updater restored the
# pristine one. It was built to work around bwrap failing to stat six
# NixOS chained /etc symlinks (host.conf, nsswitch.conf, gai.conf,
# profile, services, protocols). The 2026-08-25 post-mortem found that
# diagnosis was wrong — the actual breakage then was a stray empty
# $FEX_ROOTFS/nix directory — and that Steam worked fine without any
# shim. The shim's padded-size cache also went stale on every new
# pv-runtime release, which is what broke the client again in 2026-09.
# It is removed. Do not reintroduce it without fresh, reproduced evidence.

let
  # Replacement pressure-vessel entry point for steamwebhelper, used to inject
  # a CEF flag without modifying anything inside the Steam install.
  #
  # THE PROBLEM: the Steam client only accepts steamwebhelper's control
  # websocket when the connecting process IS the CEF *browser* process. It logs
  #   WebUITransport: Checked: <peer>/<expected> -> Connection rejected
  # and requires peer == expected. By default Chromium runs its network service
  # out-of-process, so the websocket arrives from the network-service child and
  # is always refused. The UI then fails with "Unexpected Transport Error" every
  # ~30s (8 reconnect attempts x 5s backoff), and pressing "Continue anyway"
  # only buys one more cycle. --single-process collapses renderer, network and
  # GPU into the browser process, so the browser itself is the peer and the
  # connection is accepted (verified: rejections always log a "Checked:" line;
  # with this there are none, plus 0 websocket failures and 0 webhelper
  # restarts, and the window title becomes "Steam" instead of the error).
  #
  # THE HOOK: Steam's own ubuntu12_64/steamwebhelper.sh ends with
  #   : "${STEAM_RUNTIME_STEAMRT:=.../steamrt64/pv-runtime/steam-runtime-steamrt}"
  #   exec "${STEAM_RUNTIME_STEAMRT}/_v2-entry-point" -- <wrap.sh> <args...>
  # so pointing that variable at this derivation lets us rewrite argv and then
  # delegate to the real entry point. Patching Steam's own scripts is NOT an
  # option: they are size+sha verified in package/steam_client_ubuntu12.installed,
  # so edits trigger an endless re-download/restart loop.
  #
  # The pressure-vessel container is deliberately KEPT. Running the webhelper
  # outside it also fixes the pid side of the check, but then Chromium cannot
  # spawn children at all — it launches them via /proc/self/exe, which under FEX
  # is the aarch64 FEXInterpreter rather than the x86 steamwebhelper (pv papers
  # over this with its "interpreter-root"), and the client could no longer
  # resolve the websocket peer at all (it reported pid 0).
  webhelperEntryPoint = pkgs.writeTextFile {
    name = "steam-webhelper-entry-point";
    executable = true;
    destination = "/_v2-entry-point";
    text = ''
      #!${pkgs.bash}/bin/bash
      REAL="$HOME/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/_v2-entry-point"

      if [ ! -x "$REAL" ]; then
        # Runtime not unpacked yet (first launch): fall back to Steam's default
        # behaviour by letting steamwebhelper.sh's own bootstrap handle it.
        echo "steam-webhelper-entry-point: $REAL missing, cannot delegate" >&2
        exit 1
      fi

      # argv is: -- <steamwebhelper_sniper_wrap.sh> <webhelper args...>
      # Insert the flag directly after the wrap script so it reaches
      # steamwebhelper (the wrap script execs ./steamwebhelper "$@").
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
    # bubblewrap on PATH is REQUIRED — steam.sh's check_requirements step
    # (`steam-runtime-check-requirements`) does a `which bwrap` fork+exec
    # to test that user namespaces work. Without it on PATH the test child
    # is killed by the parent's timeout (SIGTERM) and check-requirements
    # exits 71, which steam.sh translates to the user-facing
    #   "Steam now requires user namespaces to be enabled."
    # error. bwrap isn't in /run/current-system/sw/bin by default on
    # NixOS Asahi, and writeShellApplication strips PATH to just
    # runtimeInputs, so we have to add it explicitly here.
    runtimeInputs = [ pkgs.muvm pkgs.fex pkgs.coreutils pkgs.bubblewrap ];
    text = ''
      set -euo pipefail

      STEAM_DIR="''${HOME}/.local/share/Steam"
      STEAM_SH="''${STEAM_DIR}/steam.sh"
      # FEX uses XDG_DATA_HOME (~/.local/share/fex-emu) since v2400; the
      # ~/.fex-emu legacy path is only consulted if the XDG one is empty.
      FEX_ROOTFS_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/fex-emu/RootFS"

      # FEX accepts either a squashfs/erofs file (mounted via FUSE) or a
      # plain extracted directory. FUSE inside the muvm guest is unreliable
      # (libkrun's /dev/fuse setup denies user access), so we prefer an
      # extracted directory and only fall back to a packed image.
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

      # srt-logger (steam-runtime-tools' log multiplexer) hangs inside the
      # muvm guest waiting for a SRT_LOGGER_READY=1 handshake it never
      # writes — its daemonize / journald setup fails silently in this env.
      # Disabling it lets steam.sh exec into the actual client. Steam still
      # logs to its own stderr / Steam UI.
      export STEAM_RUNTIME_LOGGER=0

      # steam.sh's check_shared_libraries calls host `ldd` on the 32-bit
      # x86 binary to look for missing libs. That can never work here: the
      # host has no 32-bit dynamic linker, and ldd doesn't know about
      # FEX_ROOTFS. STEAMOS=1 is the only flag inside steam.sh that
      # short-circuits this check; the actual Steam client detects "real"
      # SteamOS via /etc/os-release (NixOS), so this env var is purely a
      # workaround for the wrapper script's preflight.
      export STEAMOS=1

      # Vulkan ICD pinning: the FEX rootfs's Mesa enumerates both the
      # Asahi Honeykrisp driver (M1 Max) and llvmpipe (CPU/software
      # fallback) plus other Mesa drivers (intel, radeon, ...) that
      # ship in the Ubuntu Mesa package but obviously can't drive
      # this machine. Steam's GPU autoselect sometimes picks llvmpipe,
      # which is brutally slow and has been observed to crash
      # steamwebhelper / shader subsystems after a few minutes.
      # `MESA_VK_DEVICE_SELECT=10005:0` doesn't disambiguate (both
      # GPUs share vendor 0x10005 and device 0x0000 in the muvm guest),
      # but `VK_LOADER_DRIVERS_SELECT='*asahi*'` works at the loader
      # level: only the asahi_icd.json driver is considered, llvmpipe
      # and friends never show up. Verified inside the guest with
      # `vulkaninfo --summary` — only "Apple M1 Max (G13C C0)" is
      # enumerated.
      export VK_LOADER_DRIVERS_SELECT='*asahi*'

      # Disable Steam's own Vulkan layers (fossilize shader cache +
      # in-game overlay). Both layers are installed under
      # ~/.local/share/vulkan/implicit_layer.d/ as 32+64-bit pairs.
      # They tend to crash on Asahi because the Asahi Vulkan ICD
      # doesn't implement every queue/shader feature the layers
      # introspect for. Pressure-vessel also complains about their
      # placement at startup ("Internal error: ... is not in
      # /usr/lib/pressure-vessel/overrides/share/vulkan/...").
      # Disabling them gives up shader caching and the overlay, but
      # avoids late steamwebhelper segfaults.
      export DISABLE_VK_LAYER_VALVE_steam_fossilize_64=1
      export DISABLE_VK_LAYER_VALVE_steam_fossilize_32=1
      export DISABLE_VK_LAYER_VALVE_steam_overlay_64=1
      export DISABLE_VK_LAYER_VALVE_steam_overlay_32=1

      # Use the HOST's native aarch64 bubblewrap instead of the x86_64
      # srt-bwrap that Steam ships.
      #
      # Valve's srt-bwrap is an x86_64 binary, so inside the guest it runs
      # under FEX — and bubblewrap's namespace setup is mistranslated there:
      #   bwrap: open /proc/<pid>/ns/ns failed: No such file or directory
      # (note the bogus "ns" namespace name). In practice it doesn't even
      # fail cleanly: `steam-runtime-check-requirements` hangs forever on
      # its `srt-bwrap --bind / / true` preflight, so steam.sh never reaches
      # the client and Steam silently never starts.
      #
      # It is NOT a bubblewrap version problem — host and srt-bwrap are both
      # 0.11.2. Running the identical check with the host's aarch64 build
      # succeeds, and plain x86 binaries run fine under FEX, so this is
      # specific to bubblewrap's namespace syscalls under emulation.
      #
      # PRESSURE_VESSEL_BWRAP is steam-runtime-tools' own supported override
      # and is honoured by both steam-runtime-check-requirements and
      # pressure-vessel (which is what actually containerises steamwebhelper).
      # The host binary is aarch64, so the kernel runs it natively and never
      # routes it through FEX; the inner COMMAND is still x86 and goes
      # through binfmt_misc → FEX as normal.
      #
      # Verified in-guest: check-requirements returns 124 (timeout) without
      # this and 0 with it.
      #
      # This replaces the old srt-bwrap shim — see the HISTORY note at the
      # top of this file. Same goal, but through the documented mechanism
      # instead of overwriting ~22 of Steam's own binaries.
      export PRESSURE_VESSEL_BWRAP=${pkgs.bubblewrap}/bin/bwrap

      # Make steamwebhelper.sh use our entry point so it gets --single-process.
      # See the webhelperEntryPoint comment above for why this is required.
      export STEAM_RUNTIME_STEAMRT=${webhelperEntryPoint}

      ulimit -c unlimited || true

      # muvm's `-e VAR` inherit form is a HARD ERROR when VAR is unset:
      #   Error: Failed to prepare environment variables
      #   Caused by: 0: Failed to get `XCURSOR_THEME` env var
      #              1: environment variable not found
      # and muvm exits before the VM is even created.
      #
      # This bites specifically on the cursor variables. Hyprland exports
      # XCURSOR_*/HYPRCURSOR_* into the *shell* environment, but they are
      # not in the systemd --user / D-Bus activation environment that the
      # .desktop entry is launched from. Passing them unconditionally means
      # Steam starts fine from a terminal and dies instantly from the app
      # launcher, with the error going to the journal where nobody sees it.
      #
      # So: forward only the variables that are actually set.
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

      # CEF-based Steam UI scales via -forcedesktopscaling; user can
      # override by passing a trailing -forcedesktopscaling=N (last one
      # wins inside the client).
      #
      # The `--` is required: without it muvm's bpaf-based CLI parses
      # `-forcedesktopscaling=2.0` as one of its own options and the
      # downstream VM creation fails with
      #   Error: Failed to create the microVM
      #   Caused by: Invalid argument (os error 22)
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
in
{
  environment.systemPackages = [
    pkgs.muvm
    pkgs.fex
    pkgs.passt
    pkgs.squashfsTools  # unsquashfs, to extract the FEX rootfs to a dir
    steam-muvm
    steam-muvm-desktop
  ];

  # /dev/kvm is 0660 root:kvm via systemd udev rules; muvm needs it.
  users.users.${username}.extraGroups = [ "kvm" ];

  # Steam Runtime scripts have #!/bin/bash shebangs that NixOS doesn't
  # satisfy by default. The muvm guest sees /bin via virtiofs, so the
  # symlink on the host fixes the guest too.
  #
  # /usr/lib must exist (empty is fine) so Steam's pressure-vessel can
  # bwrap-bind it when bootstrapping steamwebhelper. PV falls back to its
  # bundled steam-runtime libs once the path stat()s OK.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    "d /usr 0755 root root - -"
    "d /usr/lib 0755 root root - -"
  ];

}
