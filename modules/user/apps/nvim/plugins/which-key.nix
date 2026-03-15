{
  programs.nixvim.plugins.which-key = {
    enable = true;
    settings = {
      spec = [
        {
          __unkeyed-1 = "<leader>c";
          group = "Code";
        }
        {
          __unkeyed-1 = "<leader>u";
          group = "UI/Utils";
        }
        {
          __unkeyed-1 = "<leader>e";
          desc = "Explorer";
        }
		{
   		  __unkeyed-1 = "<leader>b";
      	  group = "Buffer";
    	}
		{
		  __unkeyed-1 = "g";
		  desc = "Goto";
		}
      ];
    };
  };
}
