{ pkgs, inputs, ... }:
{
  imports = [
    ./options.nix
    ./ui.nix
    ./lsp.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "actions-preview";
        src = inputs.actions-preview;
      })
    ];

	extraConfigLuaPre = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
    '';

	globals.mapleader = " "; 
    globals.maplocalleader = " ";

    keymaps = [
      {
        mode = "n";
        key = "<leader>ca";
        action = ''<cmd>lua require("actions-preview").code_actions()<CR>'';
        options = { desc = "Code Actions Preview"; silent = true; };
      }

      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Explorer NeoTree";
      }

      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Go to Left Window"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Go to Lower Window"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Go to Upper Window"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Go to Right Window"; }

      { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Prev Buffer"; }
      { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next Buffer"; }

      # --- Utilities ---
      { mode = "n"; key = "<leader>uh"; action = "<cmd>nohlsearch<cr>"; options.desc = "No Highlight"; }
    ];

    plugins = {
      lualine.enable = true;
      bufferline.enable = true;
      treesitter.enable = true;
      telescope.enable = true;
      
      neo-tree = {
        enable = true;
        filesystem.followCursor = true;
        settings = {
          enable_git_status = true;
          window.mappings = {
            "l" = "open";
            "h" = "close_node";
          };
        };
      };
    };

    extraConfigLua = ''
      require("actions-preview").setup {
        diff = {
          algorithm = "patience",
          ignore_whitespace = true,
        },
        telescope = require("telescope.themes").get_dropdown {
          winblend = 10,
          previewer = false,
        },
      }
    '';
  };
}
