{
  programs.nixvim.plugins.neo-tree = {
    enable = true;
    filesystem.followCurrentFile.enabled = true;
    settings = {
      enable_git_status = true;
      # New file from the tree: make clangd re-resolve includes (see lsp.nix).
      event_handlers = [
        {
          event = "file_added";
          handler.__raw = "function() _G.clangd_refresh() end";
        }
      ];
      window.mappings = {
        "l" = "open";
        "h" = "close_node";
      };
    };
  };
}
