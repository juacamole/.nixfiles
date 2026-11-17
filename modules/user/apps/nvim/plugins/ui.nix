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
      -- Ashen's structure (mostly-monochrome ramp + a few warm accents),
      -- repainted with the "ink & cream" palette shared with kitty / the bar:
      -- cool lavender-gray ramp up to cream; IDE-like accents: purple
      -- keywords, yellow functions, green strings, blue types, teal numbers,
      -- gray comments, red only for errors/deletions.
      require("ashen").setup({
        transparent = true,
        colors = {
          background = "#1d1c24",
          red_flame = "#e89a8a",       -- errors
          red_glowing = "#9fd3a3",     -- strings
          red_ember = "#c9a6e0",       -- keywords, titles, preproc (purple, IDE-style)
          red_kindling = "#e89a8a",
          red_burnt_crimson = "#c98579",
          red_brick = "#8a5a55",
          red_deep_ember = "#5e3f3f",
          red_ashen = "#4a3438",
          orange_glow = "#e6c88a",     -- current search
          orange_blaze = "#9ab4e0",    -- types, namespaces
          orange_smolder = "#c9a6e0",  -- diff change
          orange_golden = "#e6c88a",   -- warnings
          blue = "#9fd3cf",            -- builtin variables
          blue_dark = "#3d3a4f",
          green_light = "#9fd3a3",
          green = "#5f8a63",
          g_0 = "#ece6d8",
          g_1 = "#ece6d8",             -- bright: identifiers, functions
          g_2 = "#cfcad2",
          g_3 = "#b3aec0",             -- normal text
          g_4 = "#9b97ad",             -- text
          g_5 = "#85819a",
          g_6 = "#6b6780",             -- muted: comments
          g_7 = "#4f4c5e",
          g_8 = "#3d3a4f",             -- track: visual, pmenu, line numbers
          g_9 = "#2a2933",             -- cursorline
          g_10 = "#24232c",            -- surface
          g_11 = "#24232c",
          g_12 = "#0f0e13",            -- ink
          orange = "#e6c88a",
          yellow = "#e6c88a",
          red = "#e89a8a",
          cyan = "#9fd3cf",
          magenta = "#c9a6e0",
          purple = "#c9a6e0",
        },
        hl = {
          merge_override = {
            -- ashen paints these with its accents; too loud with yellow
            ["@operator"] = { "g_4" },
            ["@punctuation.delimiter"] = { "g_6" },
            -- deletions red, not keyword-yellow
            DiffDelete = { "red_flame", "g_8" },
            ["@diff.minus"] = { "red_flame" },
            ["@diff.plus"] = { "green_light" },
            -- functions yellow like most IDEs (ashen leaves them plain cream)
            Function = { "orange_golden" },
            ["@function"] = { "orange_golden" },
            ["@function.call"] = { "orange_golden" },
            ["@function.builtin"] = { "orange_golden" },
            ["@function.method"] = { "orange_golden" },
            ["@function.method.call"] = { "orange_golden" },
            -- treesitter types blue like the legacy Type group
            ["@type"] = { "orange_blaze" },
            ["@type.builtin"] = { "orange_blaze" },
            -- numbers/booleans teal, not the type blue
            Number = { "blue" },
            Boolean = { "blue" },
          },
        },
      })
      -- nixvim runs `colorscheme ashen` before extraConfigLua, so the palette
      -- above was ignored; reload now that setup() has stored it.
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
