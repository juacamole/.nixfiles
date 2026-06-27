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

    # --- Debug (DAP) ---
    { mode = "n"; key = "<leader>db"; action = "<cmd>lua require('dap').toggle_breakpoint()<cr>"; options.desc = "Toggle Breakpoint"; }
    { mode = "n"; key = "<leader>dc"; action = "<cmd>lua require('dap').continue()<cr>"; options.desc = "Continue / Start"; }
    { mode = "n"; key = "<leader>di"; action = "<cmd>lua require('dap').step_into()<cr>"; options.desc = "Step Into"; }
    { mode = "n"; key = "<leader>do"; action = "<cmd>lua require('dap').step_over()<cr>"; options.desc = "Step Over"; }
    { mode = "n"; key = "<leader>dO"; action = "<cmd>lua require('dap').step_out()<cr>"; options.desc = "Step Out"; }
    { mode = "n"; key = "<leader>dr"; action = "<cmd>lua require('dap').repl.toggle()<cr>"; options.desc = "Toggle REPL"; }
    { mode = "n"; key = "<leader>dt"; action = "<cmd>lua require('dap').terminate()<cr>"; options.desc = "Terminate"; }
    { mode = "n"; key = "<leader>du"; action = "<cmd>lua require('dapui').toggle()<cr>"; options.desc = "Toggle UI"; }

	# --- added cuz cool ---
	{ mode = "n"; key = "ö"; action = ":"; }
  ];
}
