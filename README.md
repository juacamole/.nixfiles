# .nixfiles

NixOS and Home Manager configuration for `kuan`: Hyprland, a hand-written
Quickshell desktop shell, nixvim, zsh and kitty, on two laptops.

| Host     | Machine                    | Login           |
| -------- | -------------------------- | --------------- |
| `salz`   | MacBook Pro M1 Max (Asahi) | SDDM            |
| `pommes` | Acer, Intel + Nvidia PRIME | greetd/tuigreet |

## Layout

```
flake.nix          inputs and the two hosts
hosts/<name>/      what belongs to one machine
  configuration.nix    system
  home.nix             user
modules/system/    shared NixOS modules
modules/home/      shared Home Manager modules, one per program
templates/         dev-shell flakes: rust, cpp, generic
docs/              why the non-obvious settings are what they are
```

[AGENTS.md](AGENTS.md) describes the structure and its rules in more detail.

## Apply

```bash
sudo nixos-rebuild switch --impure --flake ~/.nixfiles#salz     # or #pommes
```

Once applied, the alias `nix-switch` does the same. `--impure` is needed on
salz, where the Asahi firmware is read from `/boot`.

## First install

```bash
git clone https://github.com/juacamole/.nixfiles ~/.nixfiles
cd ~/.nixfiles
nixos-generate-config --show-hardware-config > hosts/<name>/hardware-configuration.nix
sudo nixos-rebuild switch --impure --flake .#<name>
```

## Update

```bash
nix flake update <input>
```

Update inputs one at a time. `nixpkgs` is held back on purpose, and
`apple-silicon` is pinned to match its prebuilt kernel.

## Dev-shell templates

```bash
template rust my-project     # or: cpp, generic
```
