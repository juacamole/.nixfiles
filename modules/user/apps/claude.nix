{ pkgs, ... }: {
	home.packages = with pkgs; [
		claude-code
		claude-monitor
		claude-code-router
	];
}
