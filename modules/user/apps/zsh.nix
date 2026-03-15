{ pkgs, config, lib, ... }:
let
  gold = "#c8b078";
  goldBright = "#dac48a";
  goldDim = "#8b7355";
  brownLight = "#b0956e";
  greenOk = "#a9b665";
  redErr = "#b87a3d";
  ornament = "#585858";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch --flake ~/.nixfiles#main";
      nix-init = "printf 'use flake' > .envrc && direnv allow";
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
      impostor = "find . -maxdepth 3 -not -type l";
    };
    sessionVariables = {
      ANDROID_HOME = "/opt/android/sdk";
      ANDROID_SDK_ROOT = "/opt/android/sdk";
      CAPACITOR_ANDROID_STUDIO_PATH = "/opt/android-studio/bin/studio.sh";
    };
    initContent = ''
      export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[╭─](${ornament})"
        "$os"
        "$directory"
        "$git_branch"
        "$git_status"
        "$fill"
        "$cmd_duration"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$time"
        "[─╮](${ornament})"
        "$line_break"
        "[╰─](${ornament})"
        "$character"
      ];
      palette = "parchment";
      palettes.parchment = {
        gold = gold;
        gold_bright = goldBright;
        gold_dim = goldDim;
        brown_light = brownLight;
        green_ok = greenOk;
        red_err = redErr;
        ornament_col = ornament;
      };
      os = {
        disabled = false;
        style = "fg:gold_dim";
      };
      directory = {
        style = "bold fg:gold_bright";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = true;
      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        style = "fg:green_ok";
        symbol = " ";
      };
      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        style = "fg:gold";
        modified = "!";
        staged = "+";
        untracked = "?";
        conflicted = "~";
        ahead = "⇡$count";
        behind = "⇣$count";
        stashed = "*$count";
      };
      fill = {
        symbol = "·";
        style = "fg:ornament_col";
      };
      character = {
        success_symbol = "[❯](fg:green_ok)";
        error_symbol = "[❯](fg:red_err)";
        vimcmd_symbol = "[❮](fg:gold_bright)";
      };
      cmd_duration = {
        min_time = 3000;
        format = "[$duration]($style) ";
        style = "fg:gold_dim";
      };
      nix_shell = {
        format = "[$symbol$state]($style) ";
        style = "fg:gold_bright";
        symbol = " ";
      };
      nodejs = {
        format = "[$symbol$version]($style) ";
        style = "fg:brown_light";
        detect_files = [ "package.json" ];
      };
      python = {
        format = "[$symbol$virtualenv]($style) ";
        style = "fg:brown_light";
      };
      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "fg:gold_dim";
        time_format = "%H:%M:%S";
      };
    };
  };
}
