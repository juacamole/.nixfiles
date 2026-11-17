{ config, lib, osConfig, ... }:
let
  p = (import ./palette.nix).inkCream;

  # Claude Code against local ollama. The token is a dummy but has to be set,
  # or the CLI silently bills the real account. Background: docs/llm.md.
  claudeLocal = lib.concatStringsSep " " [
    "BUN_CONFIG_HTTP_IDLE_TIMEOUT=3600"
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384"
    "ANTHROPIC_BASE_URL=http://localhost:11434"
    "ANTHROPIC_AUTH_TOKEN=ollama"
    "ANTHROPIC_MODEL=qwen3-coder-next"
    "ANTHROPIC_SMALL_FAST_MODEL=qwen3-coder-next"
    "claude"
  ];
in {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nix-switch = "nh os switch ${config.home.homeDirectory}/.nixfiles --impure -H ${osConfig.networking.hostName}";
      nix-init = "printf 'use flake' > .envrc && direnv allow";
      claude-local = claudeLocal;
      gemini = "npx https://github.com/google-gemini/gemini-cli";
      vim = "nvim";
      vi = "nvim";
      ff = "fastfetch";
      ll = "ls -la";
      crun = "cargo run";
      impostor = "find . -maxdepth 3 -not -type l";
      logout = "hyprctl dispatch exit";
      kys = "shutdown now";
      retard = "reboot";
      ":3" = "echo 'kys'";
    };

    sessionVariables = {
      ANDROID_HOME = "/opt/android/sdk";
      ANDROID_SDK_ROOT = "/opt/android/sdk";
      CAPACITOR_ANDROID_STUDIO_PATH = "/opt/android-studio/bin/studio.sh";
    };

    initContent = ''
      export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

      template() {
        if [ -z "$1" ]; then
          echo "usage: template <rust|cpp|generic> [dir]"; return 1
        fi
        local dir="''${2:-.}"
        mkdir -p "$dir" || return
        (cd "$dir" && nix flake init -t ~/.nixfiles#"$1") || return
        [ -f "$dir/.envrc" ] && direnv allow "$dir"
      }
    '';
  };

  programs.fzf = {
    enable = true;
    historyWidget.zsh.command = "";
  };
  programs.zoxide.enable = true;
  programs.nix-index.enable = true;

  # Atuin owns Ctrl-R; the up arrow stays plain zsh history.
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/.nixfiles";
  };

  programs.git.enable = true;
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[╭─](${p.track})"
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
        "[─╮](${p.track})"
        "$line_break"
        "[╰─](${p.track})"
        "$character"
      ];
      palette = "ink_cream";
      palettes.ink_cream = {
        text_col = p.text;
        muted = p.muted;
        bright = p.bright;
        green_ok = p.green;
        red_err = p.red;
        ornament_col = p.track;
      };
      os = {
        disabled = false;
        style = "fg:muted";
      };
      directory = {
        style = "bold fg:bright";
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
        style = "fg:text_col";
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
        vimcmd_symbol = "[❮](fg:text_col)";
      };
      cmd_duration = {
        min_time = 3000;
        format = "[$duration]($style) ";
        style = "fg:muted";
      };
      nix_shell = {
        format = "[$symbol$state]($style) ";
        style = "fg:text_col";
        symbol = " ";
      };
      nodejs = {
        format = "[$symbol$version]($style) ";
        style = "fg:bright";
        detect_files = [ "package.json" ];
      };
      python = {
        format = "[$symbol$virtualenv]($style) ";
        style = "fg:bright";
      };
      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "fg:muted";
        time_format = "%H:%M:%S";
      };
    };
  };
}
