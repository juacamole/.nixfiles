{ pkgs, ... }:
{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;
      lua_ls.enable = true;
      # JavaScript/TypeScript completion, diagnostics, go-to-definition
      ts_ls.enable = true;
      # ESLint diagnostics/code actions; uses the project's eslint config + node_modules
      eslint.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      # Java diagnostics, quick-fixes, completion (Eclipse JDT language server)
      jdtls.enable = true;
      # C/C++. package = null -> use the clang-tools clangd already on PATH
      # (from home.packages) instead of pulling a duplicate LLVM closure.
      clangd = {
        enable = true;
        package = null;
        # Nix compilers get include paths injected at build time (cc-wrapper,
        # NIX_CFLAGS_COMPILE), so clangd can't see them on its own.
        # --query-driver: let clangd ask the nix-store compiler named in
        # compile_commands.json for its real system include dirs.
        cmd = [
          "clangd"
          "--background-index"
          "--clang-tidy"
          "--query-driver=/nix/store/*/bin/*,/etc/profiles/per-user/*/bin/*,/run/current-system/sw/bin/*"
        ];
        # No compile_commands.json: fall back to the dev shell's injected
        # flags (-isystem ... from buildInputs), read when nvim starts.
        extraOptions.init_options.fallbackFlags.__raw = ''
          vim.split(vim.env.NIX_CFLAGS_COMPILE or "", "%s+", { trimempty = true })
        '';
      };
    };
  };

  # clangd caches each open file's preamble (its #includes) and never notices
  # a header that appears later, so an include of a just-created file stays an
  # error until restart. Fix: when a file is created (written for the first
  # time in nvim, or added via neo-tree), close+reopen every buffer clangd has
  # attached, which forces it to rebuild their preambles.
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

  programs.nixvim.diagnostic.settings = {
    virtual_text = true;
    underline = true;
  };

  # CMake (>= 3.17) honours this env var: every configure writes
  # build/compile_commands.json, which clangd picks up automatically.
  home.sessionVariables.CMAKE_EXPORT_COMPILE_COMMANDS = "1";

  home.packages = with pkgs; [
    nixd
    lua-language-server
    nil
    # nvim's LSP file watcher (workspace/didChangeWatchedFiles) is disabled on
    # Linux unless inotifywait is on PATH; ts_ls/jdtls/rust_analyzer need it
    # to see files created after startup.
    inotify-tools
  ];
}
