{ inputs, pkgs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim 
    ./options.nix
    ./lsp.nix
    ./ui.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Explorer NeoTree";
      }
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Go to Left Window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Go to Lower Window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Go to Upper Window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Go to Right Window";
      }
    ];

    plugins = {
      neo-tree = {
        enable = true;
        enableGitStatus = true;
        filesystem.followCursor = true;
        settings = {
          window.mappings = {
            "l" = "open";
            "h" = "close_node";
          };
        };
      };

      bufferline = {
        enable = true;
        settings.options = {
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };

      web-devicons.enable = true;
      telescope.enable = true;
      treesitter.enable = true;
      yanky.enable = true;
      nui.enable = true;
    };
  };
}
