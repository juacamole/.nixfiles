{ pkgs, inputs, ... }:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./lsp.nix
    ./plugins/ui.nix
    ./plugins/explorer.nix
    ./plugins/which-key.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    extraConfigLuaPre = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
    '';

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "actions-preview";
        src = inputs.actions-preview;
      })
    ];
  };
}
