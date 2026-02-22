{ pkgs, lib, ... }: {
  programs.nixvim = {
    diagnostics.virtual_text = false;

    plugins = {
      blink-cmp = {
        enable = true;
        settings.keymap = {
          preset = "default";
          "<Tab>" = [ "select_next" "fallback" ];
          "<S-Tab>" = [ "select_prev" "fallback" ];
          "<CR>" = [ "accept" "fallback" ];
        };
      };

      lsp = {
        enable = true;
        servers = {
          lua_ls = {
            enable = true;
            settings.Lua = {
              diagnostics.globals = [ "vim" ];
              workspace.checkThirdParty = false;
            };
          };
          pyright.enable = true;
          ts_ls.enable = true;
        };
      };
    };

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "tiny-inline-diagnostic";
        src = pkgs.fetchFromGitHub {
          owner = "rachartier";
          repo = "tiny-inline-diagnostic.nvim";
          rev = "main";
          hash = "sha256-KWUyn6fJDQ+jSBdO9gwN9mmufgIALwjm5GboK6y5ksM=";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "actions-preview";
        src = pkgs.fetchFromGitHub {
          owner = "aznhe21";
          repo = "actions-preview.nvim";
          rev = "master";
          hash = "sha256-YUeWBXxxeurfWBi0PjUi6izqYAvUw9DHmvsuPXm7ohw="; 
        };
      })
    ];

    keymaps = [
      {
        mode = [ "n" "v" ];
        key = "<leader>ca";
        action = { __raw = "require('actions-preview').code_actions"; };
        options.desc = "Code Action with preview";
      }
    ];

    extraConfigLua = ''
      require("tiny-inline-diagnostic").setup({
        preset = "modern",
        options = { show_source = true, use_icons_from_diagnostic = true, multilines = true }
      })
      require("actions-preview").setup({
        backend = { "telescope", "nui" }
      })
    '';
  };
}
