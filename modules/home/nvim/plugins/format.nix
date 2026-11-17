{
  # clang-format comes from clang-tools on PATH.
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        c = [ "clang-format" ];
        cpp = [ "clang-format" ];
      };
      format_on_save = {
        timeout_ms = 1000;
        lsp_format = "fallback";
      };
    };
  };
}
