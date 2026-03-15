{
  programs.nixvim.keymaps = [
    # --- LSP / Goto Management ---
    {
      mode = "n";
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      options.desc = "Goto Definition";
    }
    {
      mode = "n";
      key = "gr";
      action = "<cmd>lua vim.lsp.buf.references()<CR>";
      options.desc = "Goto References";
    }
    {
      mode = "n";
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      options.desc = "Hover Documentation";
    }
    {
      mode = "n";
      key = "<leader>cr";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      options.desc = "Rename Symbol";
    }
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua require('actions-preview').code_actions()<CR>";
      options = { desc = "Code Actions"; silent = true; };
    }

    # --- Buffer Management ---
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      options.desc = "Delete Buffer";
    }
    {
      mode = "n";
      key = "<leader>ba";
      action = "<cmd>%bd|e#|bd#<cr>";
      options.desc = "Close Others";
    }
    { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Prev Buffer"; }
    { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next Buffer"; }

    # --- Navigation ---
    { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Explorer"; }
    { mode = "n"; key = "<C-h>"; action = "<C-w>h"; }
    { mode = "n"; key = "<C-j>"; action = "<C-w>j"; }
    { mode = "n"; key = "<C-k>"; action = "<C-w>k"; }
    { mode = "n"; key = "<C-l>"; action = "<C-w>l"; }
    { mode = "n"; key = "<leader>uh"; action = "<cmd>nohlsearch<cr>"; options.desc = "No Highlight"; }

	# --- added cuz cool ---
	{ mode = "n"; key = "ö"; action = ":"; }
  ];
}
