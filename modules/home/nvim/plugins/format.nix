{ pkgs, ... }: {
  # clang-format comes from clang-tools on PATH, rustfmt from the rustup toolchain.
  programs.nixvim = {
    extraPackages = [
      pkgs.nixfmt
      pkgs.prettier
      pkgs.stylua
      pkgs.ruff
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
          python = [
            "leading_tabs_to_spaces"
            "ruff_organize_imports"
            "ruff_format"
          ];
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
        # ruff refuses to parse mixed tab/space indentation, so expand tabs first.
        formatters.leading_tabs_to_spaces.format.__raw = ''
          function(_, ctx, lines, callback)
            local ts = vim.bo[ctx.buf].tabstop
            local out = {}
            for i, line in ipairs(lines) do
              local indent, rest = line:match("^([ \t]*)(.*)$")
              local width = 0
              for c in indent:gmatch(".") do
                width = c == "\t" and (math.floor(width / ts) + 1) * ts or width + 1
              end
              out[i] = string.rep(" ", width) .. rest
            end
            callback(nil, out)
          end
        '';
        format_on_save = {
          timeout_ms = 1000;
          lsp_format = "fallback";
        };
      };
    };
  };
}
