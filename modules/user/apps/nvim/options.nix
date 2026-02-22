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
    };
    autoCmd = [{
      event = [ "FileType" ];
      pattern = [ "*" ];
      callback = { __raw = "function() vim.opt_local.expandtab = false end"; };
    }];
  };
}
