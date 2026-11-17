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
    (map "K" "<cmd>lua vim.lsp.buf.hover()<CR>" "Hover Documentation")
    (map "<leader>cr" "<cmd>lua vim.lsp.buf.rename()<CR>" "Rename Symbol")
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua require('actions-preview').code_actions()<CR>";
      options = { desc = "Code Actions"; silent = true; };
    }

    (map "<leader>bd" "<cmd>bdelete<cr>" "Delete Buffer")
    (map "<leader>ba" "<cmd>%bd|e#|bd#<cr>" "Close Others")
    (map "<S-h>" "<cmd>bprevious<cr>" "Prev Buffer")
    (map "<S-l>" "<cmd>bnext<cr>" "Next Buffer")

    (map "<leader>uh" "<cmd>nohlsearch<cr>" "No Highlight")
    { mode = "n"; key = "ö"; action = ":"; }
  ];
}
