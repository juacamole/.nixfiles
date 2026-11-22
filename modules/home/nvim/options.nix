{
  programs.nixvim = {
    globals.editorconfig = true;

    opts = {
      spell = true;
      spelllang = [ "en_us" ];
      title = true;
      titlestring = "NixVim";

      expandtab = false;
      shiftwidth = 4;
      tabstop = 4;

      number = true;
      relativenumber = true;
      cursorline = true;
      scrolloff = 10;

      clipboard = "unnamedplus";

      undofile = true;
      signcolumn = "yes";
      ignorecase = true;
      smartcase = true;
      splitright = true;
      splitbelow = true;
      updatetime = 250;
    };

    autoCmd = [
      # Overrides filetype plugins that set expandtab. Python keeps spaces to match ruff.
      {
        event = [ "FileType" ];
        pattern = [ "*" ];
        callback.__raw = "function() vim.opt_local.expandtab = vim.bo.filetype == 'python' end";
      }
      {
        event = [ "TextYankPost" ];
        callback.__raw = "function() vim.hl.on_yank({ timeout = 200 }) end";
      }
    ];
  };
}
