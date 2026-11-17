# Steam on Asahi (`hosts/salz/steam-muvm.nix`)

`steam-muvm` boots a libkrun microVM with muvm. The guest mounts the host
root over virtiofs, bridges Wayland, X11, PipeWire and input, and passes the
Asahi GPU through. FEX-Emu translates x86_64 inside the guest.

## One-time setup

Two pieces are large runtime blobs under Valve's and FEX's licences, so they
are not in Nix. The wrapper prints these commands when either is missing.

```sh
# FEX root filesystem, extracted to a directory
FEXRootFSFetcher -y -x --distro-name=Ubuntu --distro-version=24_04
unsquashfs -d ~/.local/share/fex-emu/RootFS/Ubuntu_24_04 \
           ~/.local/share/fex-emu/RootFS/Ubuntu_24_04.sqsh

# Steam itself (the first launch downloads about 5 GB more)
mkdir -p ~/.local/share/Steam
curl -L https://repo.steampowered.com/steam/archive/precise/steam_latest.tar.gz \
  | tar -xz -C ~/.local/share/Steam --strip-components=1
```

An extracted rootfs is preferred over the squashfs image, because FUSE is
unreliable inside the guest (libkrun denies user access to `/dev/fuse`).

## What each workaround fixes

Every one of these was reproduced. Removing one brings its failure back.

| Setting | Failure without it |
| --- | --- |
| `bubblewrap` in `runtimeInputs` | steam.sh checks for user namespaces by running `bwrap` from PATH. Without it the check exits 71 and Steam reports "Steam now requires user namespaces to be enabled." |
| `STEAM_RUNTIME_LOGGER=0` | srt-logger waits forever for a `SRT_LOGGER_READY` handshake that never arrives in the guest, and steam.sh hangs. |
| `STEAMOS=1` | steam.sh runs the host `ldd` on a 32-bit x86 binary. That cannot work here, and this variable is the only switch that skips the check. |
| `VK_LOADER_DRIVERS_SELECT='*asahi*'` | The rootfs's Mesa also offers llvmpipe and other drivers. Steam sometimes picks llvmpipe, which is very slow and crashes the web helper after a few minutes. `MESA_VK_DEVICE_SELECT` cannot tell the devices apart in the guest. |
| `DISABLE_VK_LAYER_VALVE_*` | Steam's fossilize and overlay Vulkan layers crash on the Asahi driver. The cost is no shader cache and no overlay. |
| `PRESSURE_VESSEL_BWRAP` (host bwrap) | Steam's own `srt-bwrap` is x86 and runs under FEX, where its namespace setup breaks and the requirements check hangs. The host's aarch64 bwrap runs natively. This is not a version problem: both are 0.11.2. |
| `STEAM_RUNTIME_STEAMRT` (entry-point wrapper) | See below. |
| forwarding only variables that are set | `muvm -e VAR` is a hard error when VAR is unset. The cursor variables exist in a terminal but not in the launcher's environment, so Steam started from a terminal and died instantly from the app launcher. |
| `--` before the Steam arguments | muvm otherwise parses `-forcedesktopscaling=2.0` as its own option and fails with "Failed to create the microVM". |
| `/bin/bash` symlink, empty `/usr/lib` | Steam Runtime scripts use `#!/bin/bash`, and pressure-vessel needs `/usr/lib` to exist to bind it. The guest sees both through virtiofs. |
| `kvm` group | muvm needs `/dev/kvm`. |

`-forcedesktopscaling=2.0` sets the UI scale. A later
`-forcedesktopscaling=N` on the command line overrides it.

## The web helper wrapper

Steam accepts the web helper's control websocket only when the connecting
process is the CEF *browser* process. Chromium normally runs its network
service in a child process, so the connection comes from the wrong PID and
is refused: the UI shows "Unexpected Transport Error" about every 30
seconds. `--single-process` folds the network service into the browser
process, and the connection is accepted.

The flag is injected without touching Steam's files. `steamwebhelper.sh`
ends by running `${STEAM_RUNTIME_STEAMRT}/_v2-entry-point`, so pointing that
variable at a small wrapper lets it add the flag and then call the real
entry point.

- Patching Steam's scripts is not an option: they are size- and
  checksum-verified, and an edit starts an endless re-download loop.
- The pressure-vessel container is kept on purpose. Outside it, Chromium
  cannot spawn its children under FEX at all.

## History: the srt-bwrap shim

This module once overwrote all of Steam's `srt-bwrap` binaries with a padded
aarch64 build and re-applied it every few seconds. The diagnosis behind it
was wrong (the real problem then was a stray empty `$FEX_ROOTFS/nix`
directory), and the shim broke on every runtime update. It was removed.
`PRESSURE_VESSEL_BWRAP` does the same job through a supported setting. Do
not bring the shim back without fresh, reproduced evidence.

## Window rules

Steam recreates its main window whenever the web helper crashes, and the new
window would land on the focused workspace. `modules/home/hyprland/rules.nix`
pins it to workspace 9.
