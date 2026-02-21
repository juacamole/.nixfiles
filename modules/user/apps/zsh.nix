{ pkgs, config, lib, ... }: { # Added lib here
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Aliases
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch --flake ~/.nixfiles#main";
      kys = "shutdown now";
      vim = "nvim";
      vi = "nvim";
      retard = "reboot";
      ":3" = "echo 'kys'";
      ff = "fastfetch";
      ll = "ls -la";
      logout = "hyprctl dispatch exit";
      crun = "cargo run";
      battery = "cat /sys/class/power_supply/BAT1/capacity";
      gemini = "npx https://github.com/google-gemini/gemini-cli";
    };

    # Environment Variables
    sessionVariables = {
      ANDROID_HOME = "/opt/android/sdk";
      ANDROID_SDK_ROOT = "/opt/android/sdk";
      CAPACITOR_ANDROID_STUDIO_PATH = "/opt/android-studio/bin/studio.sh";
    };

    # Powerlevel10k Setup
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        typeset -g POWERLEVEL9K_DIR_FOREGROUND='#D053A1'
        typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#D053A1'
        typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='#D053A1'

        export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
      ''
    ];
  };
}
