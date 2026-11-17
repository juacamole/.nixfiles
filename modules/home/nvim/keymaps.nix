let
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options.desc = desc;
  };
in {
  # Plugin keymaps live with their plugin (plugins/*.nix).
  programs.nixvim.keymaps = [
    (map "gd" "<cmd>lua vim.lsp.buf.definition()<CR>" "Goto Definition")
    (map "gr" "<cmd>lua vim.lsp.buf.references()<CR>" "Goto References")
    (map "gD" "<cmd>lua vim.lsp.buf.declaration()<CR>" "Goto Declaration")
    (map "gi" "<cmd>lua vim.lsp.buf.implementation()<CR>" "Goto Implementation")
    (map "gy" "<cmd>lua vim.lsp.buf.type_definition()<CR>" "Goto Type Definition")
    (map "K" "<cmd>lua vim.lsp.buf.hover()<CR>" "Hover Documentation")
    (map "<leader>cr" "<cmd>lua vim.lsp.buf.rename()<CR>" "Rename Symbol")
    (map "<leader>cd" "<cmd>lua vim.diagnostic.open_float()<CR>" "Line Diagnostics")
    (map "<leader>ci" "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<CR>" "Toggle Inlay Hints")
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua require('actions-preview').code_actions()<CR>";
      options = { desc = "Code Actions"; silent = true; };
    }

    # Snacks.bufdelete keeps the window; :bdelete closes it and neo-tree fills the screen.
    (map "<leader>bd" "<cmd>lua Snacks.bufdelete()<cr>" "Delete Buffer")
    (map "<leader>ba" "<cmd>lua Snacks.bufdelete.other()<cr>" "Close Others")
    (map "<S-h>" "<cmd>bprevious<cr>" "Prev Buffer")
    (map "<S-l>" "<cmd>bnext<cr>" "Next Buffer")

    (map "<leader>uh" "<cmd>nohlsearch<cr>" "No Highlight")
    { mode = "n"; key = "ö"; action = ":"; }
  ];
}
