{ pkgs, ... }: {
  programs.nixvim = {
    colorscheme = "ashen";

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "ashen";
        src = pkgs.fetchFromGitHub {
          owner = "ficcdaf";
          repo = "ashen.nvim";
          rev = "main";
          hash = "sha256-yC9V58zieE8YvEuAnJhEOgONrudUJgQFqC59cKo97/g=";
        };
      })
    ];

    extraConfigLua = ''
      require("ashen").setup({ transparent = true })

      local hl_groups = {
        "Normal", "NormalNC", "NormalFloat", "FloatBorder",
        "SignColumn", "StatusLine", "StatusLineNC",
        "EndOfBuffer", "MsgArea", "Pmenu", "TeleBorder"
      }
      for _, group in ipairs(hl_groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
      end

      local has_telescope, _ = pcall(require, "telescope")
      if has_telescope then
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
      end
    '';

    plugins = {
      telescope.enable = true;
      treesitter.enable = true;

      bufferline = {
        enable = true;
        settings.options = {
          separator_style = "thin";
          always_show_bufferline = true;
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              text_align = "left";
              separator = true;
            }
          ];
        };
      };

      lualine = {
        enable = true;
        settings = {
          options.theme = "ashen";
          sections = {
            lualine_a = [ { __unkeyed-1 = "mode"; icon = ""; } ];
            lualine_y = [ "progress" ];
            lualine_z = [ "location" ];
          };
        };
      };

      noice = {
        enable = true;
        settings.cmdline.view = "cmdline";
      };
    };
  };
}
