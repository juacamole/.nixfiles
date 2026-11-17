{ pkgs, config, lib, flakeTarget, ... }:
let
  # "Ink & cream" set, shared with the quickshell bar / hyprland / hyprlock.
  textCol = "#9b97ad";   # text — secondary info
  muted = "#6b6780";     # ambient info (os, time, duration)
  bright = "#ece6d8";    # directory, language/runtime tags
  greenOk = "#9fd3a3";   # green
  redErr = "#e89a8a";    # red
  ornament = "#3d3a4f";  # frame lines
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch --impure --flake ~/.nixfiles#${flakeTarget}";
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
      # Claude Code against local ollama, hitting ollama's native
      # Anthropic-format endpoint directly — it serves /v1/messages (verified
      # HTTP 200), so no translating proxy is needed. claude-code-router was
      # removed for exactly this reason: it existed to bridge a gap ollama
      # now covers itself.
      #
      # AUTH_TOKEN is a throwaway that ollama ignores, but it must be set:
      # without it the CLI falls back to CLAUDE_CODE_OAUTH_TOKEN and quietly
      # bills the real API instead of running locally.
      #
      # SMALL_FAST_MODEL is deliberately the SAME model. llm.nix pins
      # OLLAMA_MAX_LOADED_MODELS=1, so pointing background tasks (titles,
      # diff summaries) at a smaller model would evict and reload 23 GB on
      # every one of them.
      # MAX_OUTPUT_TOKENS is deliberately LOW here, overriding the global
      # 1048576 from claude.nix. That global is right for Anthropic but
      # actively harmful locally: qwen3.6 runs away on long turns — measured
      # one generation of 65464 tokens over 20m21s — and at ~18 tok/s the
      # 128000 the CLI clamps to would let that run for ~2 hours. The cap is
      # the only thing bounding a pathological generation. 16384 is ~15
      # minutes worst case, still far more than a real answer needs.
      #
      # BUN_CONFIG_HTTP_IDLE_TIMEOUT matters only during prompt processing,
      # when ollama sends no bytes for minutes and Bun closes the idle
      # connection at ~300 s. Once tokens start streaming the connection
      # stays alive on its own — a 20m21s generation returned 200 fine.
      claude-local = "BUN_CONFIG_HTTP_IDLE_TIMEOUT=3600 CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384 ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_AUTH_TOKEN=ollama ANTHROPIC_MODEL=qwen3-coder-next ANTHROPIC_SMALL_FAST_MODEL=qwen3-coder-next claude";
      impostor = "find . -maxdepth 3 -not -type l";
    };
    sessionVariables = {
      ANDROID_HOME = "/opt/android/sdk";
      ANDROID_SDK_ROOT = "/opt/android/sdk";
      CAPACITOR_ANDROID_STUDIO_PATH = "/opt/android-studio/bin/studio.sh";
    };
    initContent = ''
      # CLAUDE_CODE_OAUTH_TOKEN is deliberately NOT exported here. The token
      # from `claude setup-token` is a HEADLESS/CI credential, and when it is
      # present in the environment the CLI authenticates with it INSTEAD of the
      # normal logged-in session -- verified by the startup banner:
      #     with    the var:  Sonnet 5 · Claude API · <org>
      #     without the var:  Opus 5 · Claude Max · <org>
      # So exporting it globally silently drops the Max subscription, ignores
      # settings.json model/effort, and pushes usage onto API-console billing,
      # which is what kept demanding /login. The interactive session in
      # ~/.claude/.credentials.json refreshes itself (access token ~8h, refresh
      # token ~30d), so a plain `claude` needs /login roughly monthly, not daily.
      #
      # ~/.claude/oauth-token is kept for the cases that genuinely need it --
      # CI, cron, containers. Pass it per-invocation there:
      #     CLAUDE_CODE_OAUTH_TOKEN="$(<~/.claude/oauth-token)" claude -p ...
      export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

      # Drop a flake template into an existing dir (default: cwd), no cd/git.
      #   template cpp .
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
      palette = "ink_cream";
      palettes.ink_cream = {
        text_col = textCol;
        muted = muted;
        bright = bright;
        green_ok = greenOk;
        red_err = redErr;
        ornament_col = ornament;
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
