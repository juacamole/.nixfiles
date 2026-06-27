{
  # conform.nvim: format on save. autoInstall is off by default, so clang-format
  # is taken from PATH (clang-tools in home.packages) rather than reinstalled.
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
