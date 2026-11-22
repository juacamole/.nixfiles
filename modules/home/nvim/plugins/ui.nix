{ pkgs, ... }:
let
  p = (import ../../palette.nix).inkCream;
in {
  programs.nixvim = {
    colorscheme = "ashen";

    # snacks.image converts non-PNG images with magick.
    extraPackages = [
      pkgs.imagemagick
    ];

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
      -- Ashen's slots keep their names but carry the ink & cream palette, so
      -- e.g. red_glowing is the string green and orange_blaze the type blue.
      require("ashen").setup({
        transparent = true,
        colors = {
          background = "${p.base}",
          red_flame = "${p.red}",
          red_glowing = "${p.green}",
          red_ember = "${p.magenta}",
          red_kindling = "${p.red}",
          red_burnt_crimson = "#c98579",
          red_brick = "#8a5a55",
          red_deep_ember = "#5e3f3f",
          red_ashen = "#4a3438",
          orange_glow = "${p.yellow}",
          orange_blaze = "${p.blue}",
          orange_smolder = "${p.magenta}",
          orange_golden = "${p.yellow}",
          blue = "${p.cyan}",
          blue_dark = "${p.track}",
          green_light = "${p.green}",
          green = "#5f8a63",
          g_0 = "${p.bright}",
          g_1 = "${p.bright}",
          g_2 = "#cfcad2",
          g_3 = "#b3aec0",
          g_4 = "${p.text}",
          g_5 = "#85819a",
          g_6 = "${p.muted}",
          g_7 = "#4f4c5e",
          g_8 = "${p.track}",
          g_9 = "#2a2933",
          g_10 = "${p.surface}",
          g_11 = "${p.surface}",
          g_12 = "${p.ink}",
          orange = "${p.yellow}",
          yellow = "${p.yellow}",
          red = "${p.red}",
          cyan = "${p.cyan}",
          magenta = "${p.magenta}",
          purple = "${p.magenta}",
        },
        hl = {
          merge_override = {
            ["@operator"] = { "g_4" },
            ["@punctuation.delimiter"] = { "g_6" },
            DiffDelete = { "red_flame", "g_8" },
            ["@diff.minus"] = { "red_flame" },
            ["@diff.plus"] = { "green_light" },
            Function = { "orange_golden" },
            ["@function"] = { "orange_golden" },
            ["@function.call"] = { "orange_golden" },
            ["@function.builtin"] = { "orange_golden" },
            ["@function.method"] = { "orange_golden" },
            ["@function.method.call"] = { "orange_golden" },
            ["@type"] = { "orange_blaze" },
            ["@type.builtin"] = { "orange_blaze" },
            Number = { "blue" },
            Boolean = { "blue" },
          },
        },
      })
      -- nixvim applies the colorscheme before this runs; apply it again so
      -- the palette above takes effect.
      vim.cmd.colorscheme("ashen")

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
      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
      };

      render-markdown.enable = true;

      snacks.settings = {
        indent.enabled = true;
        words.enabled = true;
        image.enabled = true;
      };

      bufferline = {
        enable = true;
        settings.options = {
          separator_style = "thin";
          always_show_bufferline = true;
          close_command.__raw = "function(n) Snacks.bufdelete(n) end";
          right_mouse_command.__raw = "function(n) Snacks.bufdelete(n) end";
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
