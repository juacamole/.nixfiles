{ pkgs, ... }: {
	home.packages = with pkgs; [
		claude-code
		claude-monitor
		claude-code-router
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
	# failing with a 400 about max_tokens, that is this. Fix by scoping it to
	# the local route instead of setting it globally:
	#     claude-local = "CLAUDE_CODE_MAX_OUTPUT_TOKENS=1048576 ccr code";
	# in zsh.nix, and dropping this block.
	# Must be programs.zsh.sessionVariables, NOT home.sessionVariables: the
	# latter writes to hm-session-vars.sh, which nothing sources in this
	# setup (the file is not even generated), so it silently does nothing.
	# Verified by comparing against ANDROID_HOME from zsh.nix, which is set
	# the same way and does reach a login shell. Merges with zsh.nix's block.

	# claude-code-router (ccr) lets the Claude Code CLI you already use run
	# against the LOCAL ollama models instead of Anthropic — the fallback for
	# "when the subscription tokens run out". It exposes an Anthropic-format
	# endpoint on 127.0.0.1:3456 and translates to ollama's OpenAI-compatible
	# API. Usage:
	#     claude       -> normal, hits Anthropic (subscription)
	#     ccr code     -> same CLI, routed to local qwen3.6  (alias: claude-local)
	#
	# Every route points at the SAME model on purpose. The Asahi Vulkan heap
	# is 31.3 GiB and llm.nix pins OLLAMA_MAX_LOADED_MODELS=1, so only one
	# model is resident at a time (qwen3.6 is 24 GiB, gpt-oss 13 GiB — they do
	# not co-fit). If "default" and "background" pointed at different models,
	# every background task (git-diff summaries, title generation) would evict
	# and reload a 24 GiB model — seconds of thrash per turn. Keeping all
	# routes on qwen3.6 means the model loads once per session and stays put.
	# gpt-oss is still listed under the provider, so `ccr model` can switch the
	# whole session to it when a lighter/faster general model is wanted.
	#
	# This file is home-manager-managed and therefore read-only; edit it here
	# and rebuild rather than via `ccr ui`. Endpoint/port are ccr defaults.
	home.file.".claude-code-router/config.json".text = builtins.toJSON {
		LOG = false;
		Providers = [
			{
				name = "ollama";
				api_base_url = "http://localhost:11434/v1/chat/completions";
				api_key = "ollama"; # ollama ignores it; ccr requires the field
				models = [ "qwen3.6:35b-a3b" "gpt-oss:20b" ];
			}
		];
		Router = {
			default = "ollama,qwen3.6:35b-a3b";
			background = "ollama,qwen3.6:35b-a3b";
			think = "ollama,qwen3.6:35b-a3b";
			longContext = "ollama,qwen3.6:35b-a3b";
			# Just under llm.nix's 64k OLLAMA_CONTEXT_LENGTH. Same model on
			# both sides of the threshold, so this is only a safety marker.
			longContextThreshold = 60000;
		};
	};
}
