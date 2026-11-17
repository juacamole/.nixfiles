let
  f = action: desc: {
    inherit action;
    options.desc = desc;
  };
in {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      keymaps = {
        "<leader>ff" = f "find_files" "Find Files";
        "<leader>fg" = f "live_grep" "Grep";
        "<leader>fw" = f "grep_string" "Grep Word Under Cursor";
        "<leader>fb" = f "buffers" "Buffers";
        "<leader>fr" = f "oldfiles" "Recent Files";
        "<leader>fs" = f "lsp_document_symbols" "Document Symbols";
        "<leader>fS" = f "lsp_dynamic_workspace_symbols" "Workspace Symbols";
        "<leader>fd" = f "diagnostics" "Diagnostics";
        "<leader>fh" = f "help_tags" "Help";
        "<leader>fk" = f "keymaps" "Keymaps";
        "<leader>f/" = f "current_buffer_fuzzy_find" "Search Buffer";
        "<leader><space>" = f "find_files" "Find Files";
      };
    };

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>f"; group = "Find"; }
    ];
  };
}
