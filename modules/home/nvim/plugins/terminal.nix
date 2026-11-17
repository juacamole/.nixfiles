{ pkgs, ... }:
let
  map = mode: key: action: desc: {
    inherit mode key;
    action.__raw = action;
    options.desc = desc;
  };
  move = key: direction: {
    mode = "n";
    inherit key;
    action.__raw = "require('smart-splits').move_cursor_${direction}";
  };
in {
  programs.nixvim = {
    extraPackages = [ pkgs.lazygit ];

    plugins = {
      snacks = {
        enable = true;
        settings = {
          lazygit.enabled = true;
          terminal.enabled = true;
        };
      };

      # <C-hjkl> across nvim splits and, at the edge, into the next kitty window.
      smart-splits.enable = true;
    };

    # Needs kitty's remote control socket (kitty.nix).
    extraConfigLua = ''
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
      (map "n" "<leader>gg" "function() Snacks.lazygit() end" "Lazygit")
      (map "n" "<leader>gf" "function() Snacks.lazygit.log_file() end" "Lazygit File History")
      (map "n" "<leader>gl" "function() Snacks.lazygit.log() end" "Lazygit Log")

      (map [ "n" "t" ] "<C-t>" "function() Snacks.terminal() end" "Toggle Terminal")
      (map "n" "<leader>tt" "function() Snacks.terminal() end" "Toggle Terminal")
      (map "n" "<leader>tv" "function() kitty_split('vsplit') end" "Kitty Split Right")
      (map "n" "<leader>th" "function() kitty_split('hsplit') end" "Kitty Split Below")

      (move "<C-h>" "left")
      (move "<C-j>" "down")
      (move "<C-k>" "up")
      (move "<C-l>" "right")
    ];

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>g"; group = "Git"; }
      { __unkeyed-1 = "<leader>t"; group = "Terminal"; }
    ];
  };
}
