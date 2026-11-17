# .nixfiles

NixOS + Home Manager flake for one user (`kuan`) on two laptops. Hyprland on
Wayland, a hand-written Quickshell desktop shell, nixvim, zsh, kitty.

| Host     | Machine                     | Arch    | Notes                                           |
| -------- | --------------------------- | ------- | ----------------------------------------------- |
| `salz`   | MacBook Pro M1 Max (Asahi)  | aarch64 | Daily driver. Local LLMs, Steam through muvm.   |
| `pommes` | Acer, Intel + Nvidia PRIME  | x86_64  | Older laptop. `.#main` is an alias for it.      |

## Layout

```
flake.nix                 inputs, mkHost, templates
hosts/<name>/
  configuration.nix       system entry point for that machine
  home.nix                user entry point: imports modules/home plus host-only bits
  ...                     everything that only makes sense on that machine
modules/system/           shared NixOS modules
  default.nix             base every host imports (locale, user, nix, docker) + desktop + audio
  bluetooth.nix sddm.nix  opt-in, imported by a host's configuration.nix
modules/home/             shared Home Manager modules
  default.nix             base every host imports
  palette.nix             the colours, defined once
  pi/ battery-saver.nix orbitty/   opt-in, imported by a host's home.nix
  hyprland/ nvim/ quickshell/ ...  one file or folder per program
templates/                `nix flake init` dev shells (rust, cpp, generic)
docs/                     the reasoning behind non-obvious settings
```

Where things go: a setting both machines want lives in `modules/`. Anything
tied to one machine lives in `hosts/<name>/`. Modules do not branch on the
host; the host's `configuration.nix` or `home.nix` sets the difference.

## Commands

```sh
nix-switch                 # alias: nh os switch ~/.nixfiles --impure -H <host>
nix eval --impure --raw .#nixosConfigurations.salz.config.system.build.toplevel.drvPath
nix build --impure --no-link .#nixosConfigurations.salz.config.system.build.toplevel
nix flake update nixpkgs-claude    # bump only claude-code
```

- `--impure` is required on salz: the Asahi firmware is read from `/boot/vendorfw`.
- Flakes only see files git knows about. `git add` new files before evaluating.
- pommes cannot be built on salz (x86_64). Evaluate it instead; that still
  catches every Nix-level mistake.
- A change that alters no behaviour leaves the `drvPath` identical: moving
  files and editing Nix comments do not affect it. Compare it before and
  after a refactor.
- sudo needs a password, so an agent cannot switch. Build to verify, and leave the switch
  to the user.

## Conventions

- Few comments. A comment states a reason the code cannot show, in one or
  two lines. Longer reasoning, measurements and history go in `docs/`, with a
  pointer from the code when it helps.
- Nix: two-space indent, no tabs, one list item per line.
- Do not change behaviour as part of a cleanup or refactor. Ask first.
- Many values look arbitrary and are measured. Before changing a number in
  `hosts/salz/llm/` or a workaround in `hosts/salz/steam-muvm.nix`, read the
  matching file in `docs/`.
- Three files contain icon-font glyphs from the Unicode private-use area that
  most tools render as nothing: `modules/home/quickshell/config/Theme.qml`,
  `modules/home/fastfetch/config.jsonc` and
  `modules/home/nvim/plugins/ui.nix`. Edit those lines surgically; never
  retype or rewrite the file from what you see.

## Things that bite

- **Inputs.** `nixpkgs` is deliberately held back (a newer Hyprland release
  breaks this config), so do not run a blanket
  `nix flake update`. `nixpkgs-claude` exists only to supply a current
  `claude-code` (overlay in `modules/system/default.nix`). `apple-silicon`
  must not follow `nixpkgs`: its own pin matches the prebuilt Asahi kernel,
  and overriding it means compiling the kernel for hours.
- **salz kernel and boot.** The apple-silicon module sets the kernel; never
  set `boot.kernelPackages` there. No GRUB, and EFI variables stay untouched.
- **llama.cpp rebuilds.** Changing `hosts/salz/llm/llama-cpp.nix` or its
  patch triggers a long compile.
- **Quickshell has no hot reload.** The QML is copied into the store; edit,
  then switch. The shell is a systemd user unit, not a Hyprland `exec-once`,
  and so is hypridle.
- **Two palettes.** `inkCream` for terminal-side programs, `night` for the
  shell and lock screen. `night` is duplicated in `Theme.qml`, which cannot
  import Nix; change both.
- **Host differences in Hyprland** (monitors, Nvidia env, `monitors.conf`)
  are set in `hosts/<name>/home.nix`, not in `modules/home/hyprland/`.

## Notes by topic

- [docs/salz.md](docs/salz.md): Asahi hardware, keyboard and trackpad daemons, Bluetooth.
- [docs/llm.md](docs/llm.md): local inference, with every measurement and rejected idea.
- [docs/steam-muvm.md](docs/steam-muvm.md): what each Steam workaround fixes.
- [docs/shell.md](docs/shell.md): Quickshell structure, flicker rules, the state scripts.
