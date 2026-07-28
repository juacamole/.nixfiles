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

let
  # Steam's bundled srt-bwrap (x86_64 under FEX, in
  # ~/.local/share/Steam/steamrt64/pv-runtime/.../srt-bwrap) refuses to
  # source-stat six specific /etc symlinks: host.conf, nsswitch.conf,
  # gai.conf, profile, services, protocols. All of them are NixOS chained
  # symlinks (/etc -> /etc/static -> /nix/store), yet other identically
  # structured ones (e.g. /etc/hosts) pass. We couldn't reach a sane
  # diagnosis — overlayfs over /etc broke muvm-guest's resolv.conf setup,
  # and bind-mounting onto the symlink chain didn't change the failure.
  #
  # Plan Z: shim srt-bwrap. Rewrite `--ro-bind <PATH> <DST>` to
  # `--ro-bind-try <PATH> <DST>` whenever PATH is one of the six
  # problem files, then delegate to the real binary. These binds are
  # non-essential (pressure-vessel runs fine without them — the steamrt
  # platform image already ships its own copies of these /etc files).
  # We save the real binary to a tmpfs path in the guest, drop the shim
  # there too, and bind-mount it on top of srt-bwrap. Entirely scoped to
  # the guest's mount namespace.
  # ~/.cache/... lives on the virtiofs-mounted host rootfs, which allows
  # exec. /run inside the muvm guest is a libkrun-managed tmpfs that's
  # mounted noexec, so stashing srt-bwrap.real there made exec fail with
  # EACCES even though the file had +x.
  bwrapWorkDir = "/home/${username}/.cache/steam-muvm";

  # Must be a real ELF, not a shell script. pressure-vessel-wrap (running
  # as x86_64 under FEX) does a "replace self with bwrap" execve. When the
  # target is a shebang script, FEX's emulated-syscall path returns ENOEXEC
  # rather than handing off to the kernel's binfmt_script — visible as
  #   E: Error replacing self with bwrap: Exec format error
  # An aarch64 ELF satisfies FEX (it just hands native binaries to the
  # kernel), runs natively, and then execv's srt-bwrap.real (x86_64) which
  # the kernel routes through FEX via binfmt_misc as normal.
  #
  # Rewrites --ro-bind / --bind / --dev-bind whose source is one of the
  # six problem /etc files (NixOS chained symlinks that bwrap can't
  # stat through into the FEX rootfs) into the -try variant. Pressure-vessel
  # passes most of its bind setup through `--args FD` (a NUL-separated arg
  # blob on a file descriptor), so the shim also slurps that fd, splits it,
  # applies the same rewrite, and inlines the result into argv — bwrap then
  # never sees --args at all.
  #
  # srt-bwrap.real is located via /proc/self/exe at runtime — not a
  # hardcoded path. See etcFixScript: the original srt-bwrap is renamed
  # to srt-bwrap.real next to where the shim is installed.
  #
  # Size constraint: Steam's BVerifyInstalledFiles compares srt-bwrap's
  # file size against the steam_client manifest; a mismatch triggers an
  # infinite "download update / extract / restart" loop. etcFixScript
  # pads this binary with zero bytes up to the original's size before
  # installing (the kernel ignores trailing bytes past the last program
  # segment), so we just need to stay UNDER the smallest expected size
  # seen so far (64624 bytes in 2026-06 manifests). Built with musl-static
  # + -Os -flto -gc-sections -norelro, the shim lands around 10 KB —
  # plenty of headroom.
  srtBwrapShim = pkgs.pkgsStatic.stdenv.mkDerivation {
    pname = "srt-bwrap-shim";
    version = "1";
    dontUnpack = true;
    src = pkgs.writeText "srt-bwrap-shim.c" ''
      #define _GNU_SOURCE
      #include <fcntl.h>
      #include <limits.h>
      #include <stdlib.h>
      #include <string.h>
      #include <sys/types.h>
      #include <unistd.h>

      #define LOG_PATH "${bwrapWorkDir}/shim.log"
      #define MAX_ARGS 16384
      #define BUF_SIZE (1024 * 1024)

      static int is_patched(const char *p) {
          static const char *const list[] = {
              "/etc/host.conf", "/etc/nsswitch.conf", "/etc/gai.conf",
              "/etc/profile",   "/etc/services",      "/etc/protocols",
          };
          for (size_t i = 0; i < sizeof(list) / sizeof(list[0]); i++)
              if (strcmp(p, list[i]) == 0) return 1;
          return 0;
      }

      static const char *try_variant(const char *flag) {
          if (strcmp(flag, "--ro-bind")  == 0) return "--ro-bind-try";
          if (strcmp(flag, "--bind")     == 0) return "--bind-try";
          if (strcmp(flag, "--dev-bind") == 0) return "--dev-bind-try";
          return NULL;
      }

      static void w(int fd, const char *s) { (void)write(fd, s, strlen(s)); }

      static int itoa10(char *buf, long v) {
          char tmp[24]; int n = 0;
          if (v == 0) { buf[0] = '0'; return 1; }
          int neg = v < 0; if (neg) v = -v;
          while (v) { tmp[n++] = '0' + (v % 10); v /= 10; }
          int j = 0; if (neg) buf[j++] = '-';
          while (n) buf[j++] = tmp[--n];
          return j;
      }

      static void log_argv(const char *tag, int argc, char **argv) {
          int fd = open(LOG_PATH, O_WRONLY | O_CREAT | O_APPEND, 0644);
          if (fd < 0) return;
          char nb[24];
          w(fd, "=== pid="); (void)write(fd, nb, itoa10(nb, getpid()));
          w(fd, " ppid=");   (void)write(fd, nb, itoa10(nb, getppid()));
          w(fd, " ");        w(fd, tag);
          w(fd, " argc=");   (void)write(fd, nb, itoa10(nb, argc));
          w(fd, "\n");
          for (int i = 0; i < argc && i < 300; i++) {
              w(fd, "  ");
              w(fd, argv[i] ? argv[i] : "(null)");
              w(fd, "\n");
          }
          close(fd);
      }

      /* BSS-only buffers: keep .data small (forced into the file by the
       * linker), keep .bss huge (virtual, doesn't bloat the on-disk
       * binary). MAX_ARGS * 16 bytes (two pointer arrays) + BUF_SIZE for
       * the --args fd slurp. */
      static char fdbuf[BUF_SIZE];
      static char *merged[MAX_ARGS];
      static char *out[MAX_ARGS];

      int main(int argc, char **argv) {
          if (argc < 1) return 127;
          log_argv("in", argc, argv);

          /* Pass 1: expand --args FD inline. PV ships the actual bind list
           * through this fd; without expansion we'd never see it in argv. */
          size_t mcount = 0;
          merged[mcount++] = argv[0];
          for (int i = 1; i < argc && mcount < MAX_ARGS - 1; i++) {
              if (i + 1 < argc && strcmp(argv[i], "--args") == 0) {
                  int fd = atoi(argv[i + 1]);
                  size_t len = 0; ssize_t n;
                  while ((n = read(fd, fdbuf + len,
                                   BUF_SIZE - 1 - len)) > 0)
                      len += (size_t)n;
                  if (n >= 0) {
                      fdbuf[len] = '\0';
                      char *p = fdbuf, *end = fdbuf + len;
                      while (p < end && mcount < MAX_ARGS - 1) {
                          if (*p == '\0') { p++; continue; }
                          merged[mcount++] = p;
                          while (p < end && *p != '\0') p++;
                      }
                      i++;  /* skip the FD arg */
                      continue;
                  }
              }
              merged[mcount++] = argv[i];
          }
          merged[mcount] = NULL;
          log_argv("merged", (int)mcount, merged);

          /* Pass 2: rewrite bind flags whose source is on the patched list. */
          size_t j = 0;
          out[j++] = merged[0];
          for (size_t i = 1; i < mcount; i++) {
              const char *tv;
              if (i + 2 < mcount &&
                  (tv = try_variant(merged[i])) != NULL &&
                  is_patched(merged[i + 1])) {
                  out[j++] = (char *)tv;
                  out[j++] = merged[i + 1];
                  out[j++] = merged[i + 2];
                  i += 2;
              } else {
                  out[j++] = merged[i];
              }
          }
          out[j] = NULL;
          log_argv("out", (int)j, out);

          /* Exec a known-good bwrap. Earlier designs looked for an
           * srt-bwrap.real sibling via /proc/self/exe, but
           * pressure-vessel copies srt-bwrap to fresh
           * var/tmp-XXXXXX/usr/libexec/... directories at runtime
           * WITHOUT copying our .real sibling, so those copies could
           * not exec into anything. Hardcoding the host bubblewrap
           * from the Nix store sidesteps that — pkgs.bubblewrap is in
           * the closure (also in steam-muvm's runtimeInputs as of the
           * check-requirements fix), so the path is guaranteed to
           * exist whenever the shim does. The host bwrap is aarch64;
           * the kernel runs it natively, and the inner COMMAND (which
           * is x86_64 — steamwebhelper or similar) goes through
           * binfmt_misc → FEX as normal. */
          execv("${pkgs.bubblewrap}/bin/bwrap", out);
          w(2, "srt-bwrap-shim: execv ${pkgs.bubblewrap}/bin/bwrap failed\n");
          return 127;
      }
    '';
    buildPhase = ''
      runHook preBuild
      # -Wl,-z,norelro is load-bearing: without it the linker materialises
      # the BSS-via-GOT region into the on-disk binary and we balloon from
      # ~10 KB to ~66 KB, blowing past the 64624-byte size budget.
      $CC -Os -s -flto -ffunction-sections -fdata-sections \
          -Wl,--gc-sections -Wl,--build-id=none -Wl,-z,norelro \
          -o srt-bwrap-shim "$src"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 srt-bwrap-shim $out/bin/srt-bwrap-shim
      runHook postInstall
    '';
  };

  etcFixScript = pkgs.writeShellScript "steam-muvm-etc-fix" ''
    #!${pkgs.bash}/bin/bash
    set -u
    PATH=${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:${pkgs.findutils}/bin
    work=${bwrapWorkDir}
    mkdir -p "$work"
    # Mirror everything to a log so we can post-mortem from outside the
    # guest (the guest's mount namespace is gone by then).
    exec > >(tee -a "$work/fix.log") 2>&1
    echo "=== steam-muvm-etc-fix $(date -u +%FT%TZ) uid=$(id -u) ==="

    src=${srtBwrapShim}/bin/srt-bwrap-shim
    echo "shim src: $src"
    [ -x "$src" ] || { echo "ERROR: shim src missing or not exec"; exit 0; }

    # Coredump capture inside the muvm guest. The host has
    # systemd-coredump but the muvm guest is a separate kernel — its
    # default core_pattern is just "core" + ulimit -c is 0, so Steam
    # segfaults vanish silently. Point core_pattern at our work dir
    # (virtiofs from host, so dumps survive guest teardown). Steam's
    # own breakpad minidumps are unreliable (they write 0 bytes when
    # the crashing thread's stack is corrupt), so the kernel-level
    # core is what we actually need for `coredumpctl gdb`-style
    # post-mortem.
    mkdir -p "$work/cores"
    chmod 0777 "$work/cores"
    echo "$work/cores/core.%P.%e.%t" > /proc/sys/kernel/core_pattern 2>/dev/null \
      || echo "WARN: failed to set core_pattern"

    # Reset the per-launch shim invocation log so we can correlate it
    # with this run.
    : > "$work/shim.log"

    # Compare files by sha256sum (coreutils, always present). Earlier
    # iteration used cmp, which lives in diffutils and isn't on the
    # script's PATH — silent missing-binary made every run hit the
    # "needs shimming" branch, which would corrupt .real on second
    # launch.
    sum() { sha256sum < "$1" | cut -d' ' -f1; }

    # We install the shim by *replacing* srt-bwrap on virtiofs in place.
    # The shim itself execs the host's bubblewrap from /nix/store (path
    # baked at build time in the C source), so we don't need to preserve
    # a copy of the original — no .real handling at all. The old design
    # saved cand → .real and the shim used /proc/self/exe to locate it,
    # but pressure-vessel copies srt-bwrap into fresh var/tmp-XXXXXX/
    # dirs at runtime WITHOUT copying our .real sibling, so the copy
    # would shim → exec(missing .real) → fail. Hardcoding the bwrap
    # path is simpler AND survives the tmp-copy case.
    #
    # Two earlier mount-based designs both broke Steam's pv-runtime
    # auto-updater (BCommitUpdatedFiles):
    #   1. File-bind shim → srt-bwrap. rename(srt-bwrap, srt-bwrap.old)
    #      returned EBUSY (error 16): can't rename a bind-mount target.
    #   2. Dir-bind a populated overlay over libexec/steam-runtime-tools-0/.
    #      rename(package/tmp/<file>, libexec/.../<file>) returned EXDEV
    #      (error 18): rename can't cross mount boundaries.
    # Both manifested as "Failed to apply update, reverting..." in the
    # Steam bootstrap log and a hard Steam restart loop.
    #
    # The plain in-place file replacement plays nicely with Steam's
    # updater renames, but two additional Steam behaviours bite:
    #
    #   - **Steam verifies file SIZE.** BVerifyInstalledFiles compares
    #     srt-bwrap's on-disk size against the steam_client manifest. If
    #     it doesn't match, Steam declares an "update available", re-
    #     downloads + reinstalls the package (restoring pristine bwrap),
    #     then restarts — an infinite loop if we keep re-shimming back to
    #     a wrong size. To get past verify, we pad the shim with zero
    #     bytes up to the candidate's current size (the kernel ignores
    #     trailing bytes past the last program segment, so the shim still
    #     runs). Padded variants are cached on disk in
    #     $work/shim-padded-<size> with a precomputed .sum so watcher
    #     polls don't re-sha256 the padded shim every cycle. The shim
    #     itself MUST be smaller than every observed expected size
    #     (smallest seen so far: 64624 bytes); see the srtBwrapShim
    #     derivation for the size-minimisation flags.
    #
    #   - **Steam's pv-runtime self-update lands mid-session**, after
    #     muvm-init runs us but before steamwebhelper's first pv launch.
    #     The watcher below polls every 3s and re-shims any drifted
    #     candidate. Without it, the freshly-extracted pristine bwrap
    #     would get used by pressure-vessel and die on /etc/host.conf.
    #
    # pressure-vessel ships srt-bwrap under several paths (one per
    # platform-runtime + tmp-XXXXXX overlay). We shim each.

    # Build (or return cached) padded shim variant at exactly target_size.
    # Echoes the path to stdout on success; returns 1 (and echoes nothing) on
    # any failure — caller MUST check the exit status before using the path.
    #
    # `install -m 755` is load-bearing: a naive `cp -f $src $pad.tmp` inherits
    # $src's mode from /nix/store (r-xr-xr-x), so the next `truncate -s` opens
    # the file for writing and gets EACCES. Silent failure → shim file stays
    # at $src_size, not target_size → Steam keeps looping on size mismatch.
    padded_shim() {
      local target=$1 src_size pad="$work/shim-padded-$1"
      src_size=$(stat -c '%s' "$src")
      if [ "$src_size" -gt "$target" ]; then
        return 1
      fi
      if [ ! -s "$pad" ] || [ ! -s "$pad.sum" ] \
         || [ "$(stat -c '%s' "$pad" 2>/dev/null)" != "$target" ]; then
        rm -f "$pad.tmp"
        install -m 755 "$src" "$pad.tmp" || { rm -f "$pad.tmp"; return 1; }
        truncate -s "$target" "$pad.tmp" || { rm -f "$pad.tmp"; return 1; }
        mv -f "$pad.tmp" "$pad" || return 1
        sum "$pad" > "$pad.sum" || return 1
      fi
      printf '%s\n' "$pad"
    }

    shim_one() {
      local cand=$1 cand_size pad pad_sum
      [ -f "$cand" ] || { echo "  not a regular file; skip"; return; }

      cand_size=$(stat -c '%s' "$cand")
      pad=$(padded_shim "$cand_size") || {
        echo "  shim too big for $cand (target $cand_size); not shimming"
        return
      }
      pad_sum=$(cat "$pad.sum")
      if [ "$(sum "$cand")" = "$pad_sum" ]; then
        return  # already shimmed at this size; nothing to do
      fi

      # Install padded shim over cand. No .real preservation: the shim
      # execs into the host's pkgs.bubblewrap from /nix/store (baked at
      # build time), so we don't need a copy of the original bwrap.
      # Pressure-vessel sometimes copies the shimmed cand to fresh
      # var/tmp-XXXXXX/ dirs without copying our siblings, and the
      # /proc/self/exe-relative .real lookup the shim used to do would
      # fail there. Hardcoded /nix/store path always works.
      if ! cp -f "$pad" "$cand"; then
        echo "  cp shim -> $cand FAILED rc=$?"
        return
      fi
      chmod 0755 "$cand"
      echo "  shimmed $cand (size $cand_size)"
    }

    # One-time cleanup of legacy srt-bwrap.real siblings from the old
    # /proc/self/exe-relative design — harmless if absent.
    find /home/${username}/.local/share/Steam \
         -path '*/libexec/steam-runtime-tools-0/srt-bwrap.real' \
         -type f -delete 2>/dev/null || true

    found=0
    while IFS= read -r cand; do
      found=$((found + 1))
      echo "candidate $found: $cand"
      shim_one "$cand"
    done < <(find /home/${username}/.local/share/Steam \
                  -path '*/libexec/steam-runtime-tools-0/srt-bwrap' \
                  -type f 2>/dev/null)
    echo "found $found candidate(s)"

    # Background watcher: pv-runtime self-update happens mid-session
    # (after muvm-init runs us, before steamwebhelper's first pv launch
    # — and again whenever Steam pulls a new SLR/pv-runtime). The update
    # overwrites our shim with a pristine srt-bwrap, and the next bwrap
    # call dies on /etc/host.conf. Poll every 3s and re-shim anything
    # that's drifted. shim_one is a no-op when the candidate already
    # matches the padded shim for its current size (cached sha256), so
    # the steady-state cost per tick is ~40 file stats + 40 sha256sums on
    # small ELFs — well under 1s on the guest.
    #
    # Stable-file check: sum twice with 200ms gap. If the file is being
    # written we'd see different sums and skip this round; the next tick
    # picks it up once writes settle.
    #
    # The watcher inherits muvm-init as ppid once this script returns
    # (muvm waits only for the -x script's main pid, not its descendants),
    # so it lives for the whole Steam session and dies with the guest.
    (
      exec </dev/null >>"$work/watcher.log" 2>&1
      echo "=== watcher start $(date -u +%FT%TZ) pid=$$ ==="
      while sleep 3; do
        while IFS= read -r cand; do
          [ -f "$cand" ] || continue
          # Stability gate: only act once two consecutive reads agree.
          cs1=$(sum "$cand" 2>/dev/null) || continue
          sleep 0.2
          cs2=$(sum "$cand" 2>/dev/null) || continue
          [ "$cs1" != "$cs2" ] && continue
          shim_one "$cand"
        done < <(find /home/${username}/.local/share/Steam \
                      -path '*/libexec/steam-runtime-tools-0/srt-bwrap' \
                      -type f 2>/dev/null)
      done
    ) &
    disown 2>/dev/null || true
    echo "watcher backgrounded (pid $!); etcFixScript exiting"
  '';

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

      # Allow kernel-level core dumps from inside the muvm guest
      # (etcFixScript points core_pattern at $work/cores). The host
      # ulimit -c is unlimited; muvm propagates rlimits to the guest.
      ulimit -c unlimited || true

      # CEF-based Steam UI scales via -forcedesktopscaling; user can
      # override by passing a trailing -forcedesktopscaling=N (last one
      # wins inside the client).
      #
      # The `--` is required: without it muvm's bpaf-based CLI parses
      # `-forcedesktopscaling=2.0` as one of its own options and the
      # downstream VM creation fails with
      #   Error: Failed to create the microVM
      #   Caused by: Invalid argument (os error 22)
      exec muvm \
        -x ${etcFixScript} \
        -e FEX_ROOTFS -e STEAM_RUNTIME_LOGGER -e STEAMOS \
        -e WAYLAND_DISPLAY -e DISPLAY -e XDG_SESSION_TYPE \
        -e XDG_RUNTIME_DIR -e XDG_DATA_DIRS \
        -e XCURSOR_THEME -e XCURSOR_SIZE \
        -e HYPRCURSOR_THEME -e HYPRCURSOR_SIZE \
        -e VK_LOADER_DRIVERS_SELECT \
        -e DISABLE_VK_LAYER_VALVE_steam_fossilize_64 \
        -e DISABLE_VK_LAYER_VALVE_steam_fossilize_32 \
        -e DISABLE_VK_LAYER_VALVE_steam_overlay_64 \
        -e DISABLE_VK_LAYER_VALVE_steam_overlay_32 \
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
