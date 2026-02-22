{ pkgs, ... }:
{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;      
      lua_ls.enable = true;    
    };
    
    keymaps.lspBuf = {
      "gd" = "definition";
      "K" = "hover";
      "<leader>cr" = "rename";
    };
  };

  programs.nixvim.diagnostics = {
    virtual_text = true;
    underline = true;
  };

  home.packages = with pkgs; [
    nixd
    lua-language-server
  ];
}
