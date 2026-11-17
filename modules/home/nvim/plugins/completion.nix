{
  programs.nixvim.plugins.blink-cmp = {
    enable = true;
    settings = {
      # <C-space> open, <C-y> accept, <C-n>/<C-p> select
      keymap.preset = "default";
      completion = {
        documentation.auto_show = true;
        accept.auto_brackets.enabled = true;
      };
      signature.enabled = true;
      sources.default = [ "lsp" "path" "snippets" "buffer" ];
    };
  };
}
