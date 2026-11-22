{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi-coding-agent;
  json = pkgs.formats.json { };

  # pi talks to the local llama.cpp router on :8080, which allam manages.
  settings = {
    defaultProvider = "salz";
    defaultModel = "qwen3.8-flash-next";
    defaultThinkingLevel = "low";
    enableInstallTelemetry = false;
    theme = "dark";
    editorPaddingX = 0;
    compaction = {
      enabled = true;
      reserveTokens = 16384;
      keepRecentTokens = 20000;
    };
    retry.provider.timeoutMs = 1800000;
  };

  models.providers.salz = {
    baseUrl = "http://127.0.0.1:8080/v1";
    api = "openai-completions";
    apiKey = "local";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
      maxTokensField = "max_tokens";
    };
    models = [
      {
        id = "qwen3.8-27b-abliterated";
        name = "Qwen3.8 27B abliterated (salz, Q4_0 + MTP)";
        reasoning = true;
        input = [ "text" ];
        contextWindow = 262144;
        maxTokens = 32768;
        # This model's template only knows low, high and xhigh.
        thinkingLevelMap = {
          minimal = null;
          low = "low";
          medium = null;
          high = "high";
          xhigh = "xhigh";
          max = null;
        };
        compat = {
          thinkingFormat = "chat-template";
          chatTemplateKwargs = {
            enable_thinking = { "$var" = "thinking.enabled"; };
            reasoning_effort = { "$var" = "thinking.effort"; };
            preserve_thinking = true;
          };
        };
      }
      {
        id = "qwen3.8-flash-next";
        name = "Qwen3.8 Flash-Next (salz, Q2_0, 6B active)";
        reasoning = true;
        input = [ "text" ];
        contextWindow = 262144;
        maxTokens = 32768;
        compat.thinkingFormat = "qwen-chat-template";
      }
    ];
  };

  settingsFile = json.generate "pi-settings.json" settings;
  modelsFile = json.generate "pi-models.json" models;
in {
  programs.pi-coding-agent.enable = true;

  # Written as real files, not store symlinks: pi saves its own changes into
  # settings.json. On each switch these settings are merged over the existing
  # file, and models.json is replaced.
  home.activation.piConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="${cfg.configDir}"
    run mkdir -p "$dir"
    for f in settings.json models.json; do
      [ -L "$dir/$f" ] && run rm "$dir/$f"
    done
    if [ -f "$dir/settings.json" ]; then
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$dir/settings.json" ${settingsFile} > "$tmp" \
        && run install -m 644 "$tmp" "$dir/settings.json"
      rm -f "$tmp"
    else
      run install -m 644 ${settingsFile} "$dir/settings.json"
    fi
    run install -m 644 ${modelsFile} "$dir/models.json"
  '';

  home.file."${cfg.configDir}/skills/caveman".source = ./skills/caveman;
  home.file."${cfg.configDir}/extensions/tps.ts".source = ./extensions/tps.ts;
  home.file."${cfg.configDir}/extensions/allam-models.ts".source = ./extensions/allam-models.ts;
}
