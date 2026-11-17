{ pkgs, ... }: {
  # clang-format comes from clang-tools on PATH, rustfmt from the rustup toolchain.
  programs.nixvim = {
    extraPackages = [
      pkgs.nixfmt
      pkgs.prettier
      pkgs.stylua
    ];

    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          c = [ "clang-format" ];
          cpp = [ "clang-format" ];
          nix = [ "nixfmt" ];
          lua = [ "stylua" ];
          rust = [ "rustfmt" ];
          javascript = [ "prettier" ];
          typescript = [ "prettier" ];
          javascriptreact = [ "prettier" ];
          typescriptreact = [ "prettier" ];
          json = [ "prettier" ];
          css = [ "prettier" ];
          html = [ "prettier" ];
          markdown = [ "prettier" ];
          yaml = [ "prettier" ];
        };
        format_on_save = {
          timeout_ms = 1000;
          lsp_format = "fallback";
        };
      };
    };
  };
}
