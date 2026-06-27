{
  # blink.cmp: autocomplete popup. setupLspCapabilities is on by default, so
  # this automatically advertises completion capabilities to every LSP server
  # configured under plugins.lsp (clangd, rust_analyzer, nixd, lua_ls).
  programs.nixvim.plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap.preset = "default"; # <C-space> open, <C-y> accept, <C-n>/<C-p> select
      completion = {
        documentation.auto_show = true;
        accept.auto_brackets.enabled = true;
      };
      signature.enabled = true; # signature help while typing args
      sources.default = [ "lsp" "path" "snippets" "buffer" ];
    };
  };
}
