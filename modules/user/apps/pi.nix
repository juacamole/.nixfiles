{ config, lib, pkgs, ... }:
let
	cfg = config.programs.pi-coding-agent;
	json = pkgs.formats.json { };

	# pi coding agent (https://pi.dev), talking to the local llama.cpp router on :8080
	# (started and managed by allam, ~/.config/allam/allam.conf; presets in ~/models/models.ini).
	#
	# Moved here from hand-edited ~/.pi/agent/{settings,models}.json on 2026-11-14.
	# Deliberately NOT programs.pi-coding-agent.settings/models: those would make the
	# files read-only store symlinks, and pi saves its own changes (/settings, theme,
	# changelog marker) into settings.json. Instead the activation script below writes
	# normal, writable files on every nix-switch:
	#   settings.json  existing file merged with these values (these win, keys pi added stay)
	#   models.json    replaced by these values
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
		# Local models are slow (~8 t/s); a long answer can take many minutes.
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
				# The 27B template only knows reasoning_effort low/high/xhigh.
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

	home.activation.piConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
		dir="${cfg.configDir}"
		run mkdir -p "$dir"
		# Replace a leftover store symlink with a real file.
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

	# Skills: same SKILL.md format as Claude Code. The module has no skills option, so
	# link them into pi's global skills dir (read-only is fine, pi never writes skills).
	# caveman = copy of ~/.claude/skills/caveman (2026-11-14). Force it with /skill:caveman.
	home.file."${cfg.configDir}/skills/caveman".source = ./pi/skills/caveman;

	# Extensions (auto-loaded from ~/.pi/agent/extensions/*.ts).
	# tps.ts: generation and prompt-reading speed (t/s) in the footer.
	home.file."${cfg.configDir}/extensions/tps.ts".source = ./pi/extensions/tps.ts;
}
