let
  map = key: action: desc: {
    mode = "n";
    inherit key;
    action.__raw = action;
    options.desc = desc;
  };
in {
  programs.nixvim = {
    plugins = {
      # One session per directory (and git branch), saved on exit.
      persistence.enable = true;
      undotree.enable = true;
    };

    # Restores the session when nvim starts without file arguments. Explorer and
    # terminal windows are closed before saving; they come back as empty splits.
    extraConfigLua = ''
      vim.api.nvim_create_autocmd("StdinReadPre", {
        callback = function() vim.g.started_with_stdin = true end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        nested = true,
        callback = function()
          if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
            require("persistence").load()
          end
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(vim.cmd, "Neotree close")
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "terminal" and #vim.api.nvim_list_wins() > 1 then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
        end,
      })
    '';

    keymaps = [
      (map "<leader>qs" "function() require('persistence').load() end" "Restore Session")
      (map "<leader>qS" "function() require('persistence').select() end" "Select Session")
      (map "<leader>ql" "function() require('persistence').load({ last = true }) end" "Last Session")
      (map "<leader>qd" "function() require('persistence').stop() end" "Don't Save Session")
      (map "<leader>uu" "function() vim.cmd.UndotreeToggle() end" "Undo Tree")
    ];

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>q"; group = "Session"; }
    ];
  };
}
