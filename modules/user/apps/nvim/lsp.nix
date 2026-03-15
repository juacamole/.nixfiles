{ pkgs, ... }:
{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;      
      lua_ls.enable = true;    
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
    };
  };

  programs.nixvim.diagnostics = {
    virtual_text = true;
    underline = true;
  };

  home.packages = with pkgs; [
    nixd
    lua-language-server
    nil 
  ];
}
