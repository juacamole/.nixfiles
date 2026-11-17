{
  # Plugins add their own groups next to their keymaps.
  programs.nixvim.plugins.which-key = {
    enable = true;
    settings.delay = 0;
    settings.spec = [
      { __unkeyed-1 = "<leader>c"; group = "Code"; }
      { __unkeyed-1 = "<leader>u"; group = "UI/Utils"; }
      { __unkeyed-1 = "<leader>b"; group = "Buffer"; }
      { __unkeyed-1 = "g"; desc = "Goto"; }
    ];
  };
}
