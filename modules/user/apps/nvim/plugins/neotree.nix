{
  programs.nixvim.plugins.neo-tree = {
    enable = true;
    filesystem.followCursor = true;
    settings = {
      enable_git_status = true;
      window.mappings = {
        "l" = "open";
        "h" = "close_node";
      };
    };
  };
}
