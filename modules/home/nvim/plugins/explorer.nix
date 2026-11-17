{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;
      settings = {
        enable_git_status = true;
        filesystem.follow_current_file.enabled = true;
        event_handlers = [{
          event = "file_added";
          handler.__raw = "function() _G.clangd_refresh() end";
        }];
        window.mappings = {
          "l" = "open";
          "h" = "close_node";
        };
      };
    };

    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Explorer"; }
    ];

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>e"; desc = "Explorer"; }
    ];
  };
}
