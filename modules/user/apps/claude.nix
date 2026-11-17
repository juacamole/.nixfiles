{ pkgs, ... }: {
	home.packages = with pkgs; [
		claude-code
		claude-monitor
	];

	# Raise Claude Code's output cap from its 32000 default. Nothing
	# pre-allocates against this — neither the Anthropic API nor llama.cpp,
	# whose KV cache is sized from n_ctx (llm.nix pins 65536) — so a larger
	# value costs nothing by itself. It is a ceiling, not a reservation.
	#
	# 1048576 is far above any real model's output limit. On the local route
	# that is harmless: generation stops at the 65536 context long before it,
	# and at ~20 tok/s even 32000 tokens would take ~27 minutes, so this cap
	# is never the binding constraint locally. On the Anthropic route it is
	# only safe if the CLI clamps to the model maximum; if requests start
	# failing with a 400 about max_tokens, that is this. Fix by dropping this
	# block and prepending the variable to the claude-local alias in zsh.nix
	# instead, so it only applies to the local route.
	# home.sessionVariables would work equally well here — .zshenv sources
	# hm-session-vars.sh from the Nix store. This uses the zsh-scoped option
	# only to sit alongside zsh.nix's existing block; both are fine.
	#
	# Gotcha when testing this: .zshenv wraps its exports in a
	# `if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]` once-guard, and that guard
	# is already set in any running session. So a new terminal, or any shell
	# spawned from the current desktop, SKIPS the whole block and will not
	# show a newly added variable — it only inherits what was exported at
	# login. Verifying with `echo $VAR` in a new terminal therefore reports
	# a false negative. Either log out and back in, or test with:
	#     env -u __HM_ZSH_SESS_VARS_SOURCED zsh -c 'source ~/.zshenv; echo $VAR'
	programs.zsh.sessionVariables.CLAUDE_CODE_MAX_OUTPUT_TOKENS = "1048576";

	# Local prompt processing runs at ~125 tok/s (measured), so a full 64k
	# context takes ~8.5 minutes before the first token. Claude Code's
	# default request timeout is far shorter, so it aborts mid-request and
	# ollama logs a 500 for the dropped connection — which looks like ollama
	# killing the model but is not: the journal shows those tasks finishing
	# normally with truncated = 0 right after the client gave up. Observed
	# 500s at 4m50s and 1m12s against a 63221-token prompt.
	#
	# 30 minutes covers a worst-case full-context turn with margin. This only
	# raises the ceiling for waiting; it does not slow anything down, and on
	# the Anthropic route requests never get near it.
	programs.zsh.sessionVariables.API_TIMEOUT_MS = "1800000";

	# API_TIMEOUT_MS alone did NOT fix the 500s: a request from a process
	# that provably had API_TIMEOUT_MS=1800000 in its environment still died
	# at 4m45s. The giveaway is that ollama kept working for 90+ seconds
	# after the client hung up (500 logged 14:29:53, ollama still processing
	# task 52 at 14:31:21), so nothing crashed — the connection was dropped
	# from this side.
	#
	# Claude Code is a Bun build, and Bun's HTTP client applies an idle
	# timeout of ~300 s. During prompt processing the server sends no bytes
	# at all for minutes, so the connection looks idle and Bun closes it.
	# That matches the observed failures almost exactly: 4m45s and 4m50s
	# against a ~300 s default. Value is in SECONDS, not ms.
	programs.zsh.sessionVariables.BUN_CONFIG_HTTP_IDLE_TIMEOUT = "3600";

}
