{ pkgs, ... }: {
  home.packages = with pkgs; [
    claude-code
    claude-monitor
  ];

  # Long timeouts for slow local models; reasoning in docs/llm.md.
  programs.zsh.sessionVariables = {
    CLAUDE_CODE_MAX_OUTPUT_TOKENS = "1048576";
    API_TIMEOUT_MS = "1800000";
    # In seconds, not ms.
    BUN_CONFIG_HTTP_IDLE_TIMEOUT = "3600";
  };
}
