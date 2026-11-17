{ pkgs, ... }:
{
  programs.nixvim = {
    # snacks.lazygit shells out to `lazygit` from PATH.
    extraPackages = [ pkgs.lazygit ];

    plugins = {
      # snacks: floating lazygit (themed from the colorscheme, `e` in lazygit
      # opens the file in this nvim) + a toggleable terminal.
      snacks = {
        enable = true;
        settings = {
          lazygit.enabled = true;
          terminal.enabled = true;
        };
      };

      # smart-splits: <C-hjkl> moves between nvim splits and, at the edge,
      # into the neighbouring kitty window. Sets the IS_NVIM user var that
      # kitty's `--when-focus-on var:IS_NVIM` maps key off (see kitty.nix).
      smart-splits.enable = true;
    };

    extraConfigLua = ''
      -- Open a kitty split next to nvim, in nvim's cwd (needs kitty remote
      -- control over $KITTY_LISTEN_ON, see kitty.nix).
      function _G.kitty_split(location)
        if not vim.env.KITTY_LISTEN_ON then
          vim.notify("not inside kitty (no KITTY_LISTEN_ON)", vim.log.levels.WARN)
          return
        end
        vim.fn.jobstart({
          "kitty", "@", "launch", "--type=window",
          "--location=" .. location, "--cwd=" .. vim.fn.getcwd(),
        })
      end
    '';

    keymaps = [
      # --- Git ---
      { mode = "n"; key = "<leader>gg"; action.__raw = "function() Snacks.lazygit() end"; options.desc = "Lazygit"; }
      { mode = "n"; key = "<leader>gf"; action.__raw = "function() Snacks.lazygit.log_file() end"; options.desc = "Lazygit File History"; }
      { mode = "n"; key = "<leader>gl"; action.__raw = "function() Snacks.lazygit.log() end"; options.desc = "Lazygit Log"; }

      # --- Terminal ---
      { mode = [ "n" "t" ]; key = "<C-t>"; action.__raw = "function() Snacks.terminal() end"; options.desc = "Toggle Terminal"; }
      { mode = "n"; key = "<leader>tt"; action.__raw = "function() Snacks.terminal() end"; options.desc = "Toggle Terminal"; }
      { mode = "n"; key = "<leader>tv"; action.__raw = "function() kitty_split('vsplit') end"; options.desc = "Kitty Split Right"; }
      { mode = "n"; key = "<leader>th"; action.__raw = "function() kitty_split('hsplit') end"; options.desc = "Kitty Split Below"; }

      # --- Navigation across nvim splits + kitty windows ---
      { mode = "n"; key = "<C-h>"; action.__raw = "require('smart-splits').move_cursor_left"; }
      { mode = "n"; key = "<C-j>"; action.__raw = "require('smart-splits').move_cursor_down"; }
      { mode = "n"; key = "<C-k>"; action.__raw = "require('smart-splits').move_cursor_up"; }
      { mode = "n"; key = "<C-l>"; action.__raw = "require('smart-splits').move_cursor_right"; }
    ];

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>g"; group = "Git"; }
      { __unkeyed-1 = "<leader>t"; group = "Terminal"; }
    ];
  };
}
