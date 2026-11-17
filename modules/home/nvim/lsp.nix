{ pkgs, ... }: {
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;
      lua_ls.enable = true;
      ts_ls.enable = true;
      eslint.enable = true;
      jdtls.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      clangd = {
        enable = true;
        # Uses the clangd that clang-tools already puts on PATH.
        package = null;
        # --query-driver lets clangd ask the Nix compiler wrapper for its
        # include paths, which are injected at build time.
        cmd = [
          "clangd"
          "--background-index"
          "--clang-tidy"
          "--query-driver=/nix/store/*/bin/*,/etc/profiles/per-user/*/bin/*,/run/current-system/sw/bin/*"
        ];
        # Without compile_commands.json, use the dev shell's flags.
        extraOptions.init_options.fallbackFlags.__raw = ''
          vim.split(vim.env.NIX_CFLAGS_COMPILE or "", "%s+", { trimempty = true })
        '';
      };
    };
  };

  # clangd never notices a header created after it cached a file's includes.
  # Reopening every attached buffer when a file is created makes it look again.
  programs.nixvim.extraConfigLua = ''
    function _G.clangd_refresh(skip_buf)
      for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
        for buf in pairs(client.attached_buffers) do
          if buf ~= skip_buf and vim.api.nvim_buf_is_loaded(buf) then
            local uri = vim.uri_from_bufnr(buf)
            client:notify("textDocument/didClose", { textDocument = { uri = uri } })
            client:notify("textDocument/didOpen", {
              textDocument = {
                uri = uri,
                languageId = vim.bo[buf].filetype,
                version = vim.b[buf].changedtick,
                text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n",
              },
            })
          end
        end
      end
    end

    local grp = vim.api.nvim_create_augroup("ClangdNewFileRefresh", { clear = true })
    vim.api.nvim_create_autocmd("BufNewFile", {
      group = grp,
      callback = function(a) vim.b[a.buf].clangd_new_file = true end,
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = grp,
      callback = function(a)
        if vim.b[a.buf].clangd_new_file then
          vim.b[a.buf].clangd_new_file = nil
          _G.clangd_refresh(a.buf)
        end
      end,
    })
  '';

  programs.nixvim.plugins.clangd-extensions.enable = true;

  # Only in buffers clangd is attached to; the commands do not exist elsewhere.
  programs.nixvim.autoCmd = [{
    event = [ "LspAttach" ];
    callback.__raw = ''
      function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or client.name ~= "clangd" then return end
        local function map(key, cmd, desc)
          vim.keymap.set("n", key, "<cmd>" .. cmd .. "<cr>", { buffer = args.buf, desc = desc })
        end
        map("<leader>ch", "LspClangdSwitchSourceHeader", "Switch Header/Source")
        map("<leader>cs", "LspClangdShowSymbolInfo", "Symbol Info")
        map("<leader>ct", "ClangdTypeHierarchy", "Type Hierarchy")
        map("<leader>cm", "ClangdMemoryUsage", "clangd Memory Usage")
        map("<leader>cx", "ClangdAST", "AST")
      end
    '';
  }];

  programs.nixvim.diagnostic.settings = {
    virtual_text = true;
    underline = true;
  };

  # Makes every CMake configure write compile_commands.json for clangd.
  home.sessionVariables.CMAKE_EXPORT_COMPILE_COMMANDS = "1";

  home.packages = with pkgs; [
    nixd
    nil
    lua-language-server
    stylua
    tree-sitter
    # nvim's LSP file watcher is disabled on Linux without inotifywait.
    inotify-tools
  ];
}
