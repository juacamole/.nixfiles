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
      # C/C++. package = null -> use the clang-tools clangd already on PATH
      # (from home.packages) instead of pulling a duplicate LLVM closure.
      clangd = {
        enable = true;
        package = null;
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
