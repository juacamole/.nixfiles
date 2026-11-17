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
  # Mouse on: nvim's own scrollback is useless once tmux owns the screen.
  tmuxConf = pkgs.writeText "nvim-tmux.conf" ''
    set -g status off
    set -g mouse on
    set -s escape-time 0
    set -g history-limit 50000
    set -g default-terminal "tmux-256color"
    set -as terminal-features ",xterm-256color:RGB"
  '';
in {
  programs.nixvim = {
    extraPackages = [
      pkgs.lazygit
      pkgs.tmux
    ];

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
    # The terminal runs inside tmux (own socket, one session per cwd) so its
    # processes outlive nvim; reopening it reattaches.
    extraConfigLua = ''
      function _G.tmux_terminal()
        local cwd = vim.fn.getcwd()
        local base = vim.fn.fnamemodify(cwd, ":t"):gsub("[^%w_-]", "_")
        local name = "nvim-" .. base .. "-" .. vim.fn.sha256(cwd):sub(1, 8)
        Snacks.terminal({
          "tmux", "-L", "nvim", "-f", "${tmuxConf}",
          "new-session", "-A", "-s", name,
        }, { cwd = cwd, win = { position = "bottom" } })
      end


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

      (map [ "n" "t" ] "<C-t>" "function() tmux_terminal() end" "Toggle Terminal")
      (map "n" "<leader>tt" "function() tmux_terminal() end" "Toggle Terminal")
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
