# .nixfiles

NixOS configuration for `kuan` — Hyprland on Wayland, Nvidia (PRIME offload), Pipewire audio, and nixvim.

## Stack

- **OS:** NixOS (nixos-unstable)
- **WM:** Hyprland
- **Terminal:** Kitty
- **Shell:** Zsh
- **Editor:** Neovim via nixvim
- **Audio:** Pipewire
- **Login:** greetd + tuigreet
- **Browser:** Zen Browser

## Folder Structure

```
.nixfiles/
├── flake.nix                        # Entry point — inputs, outputs, HM integration
├── flake.lock                       # Pinned dependency versions
│
├── hosts/
│   └── nixos/
│       ├── configuration.nix        # Core system config (users, networking, nvidia, steam)
│       ├── grub.nix                 # GRUB bootloader config
│       └── hardware-configuration.nix
│
└── modules/
    ├── system/                      # NixOS-level modules
    │   ├── audio.nix                # Pipewire setup
    │   ├── boot.nix                 # Boot settings
    │   └── desktop.nix              # Hyprland, fonts, XDG portals
    │
    └── user/                        # Home Manager modules
        ├── home.nix                 # HM entry point — imports all apps, session vars
        └── apps/
            ├── defaults.nix         # Base packages (dev tools, gaming, utilities)
            ├── kitty.nix
            ├── zsh.nix
            ├── rofi.nix
            ├── waybar.nix
            ├── hypridle.nix
            ├── notifications.nix
            ├── gazelle.nix
            ├── claude.nix
            ├── cursor.nix
            ├── hyprland/
            │   ├── default.nix
            │   ├── binds.nix
            │   ├── monitors.nix
            │   ├── rules.nix
            │   ├── settings.nix
            │   └── hyprlock.nix
            └── nvim/
                ├── default.nix
                ├── keymaps.nix
                ├── lsp.nix
                ├── options.nix
                └── plugins/
                    ├── explorer.nix
                    ├── neotree.nix
                    ├── ui.nix
                    └── which-key.nix
```

## Apply Configuration

```bash
sudo nixos-rebuild switch --flake .#main
```

Run from the root of this repo. This builds and activates both the NixOS system configuration and the Home Manager user configuration in one step.

## First Install (fresh NixOS)

```bash
# Clone the repo
git clone https://github.com/juacamole/.nixfiles ~/.nixfiles
cd ~/.nixfiles

# Generate hardware config for your machine and replace the existing one
nixos-generate-config --show-hardware-config > hosts/nixos/hardware-configuration.nix

# Apply
sudo nixos-rebuild switch --flake .#main
```

## Update Inputs

```bash
nix flake update
```

Then rebuild with the command above.****
