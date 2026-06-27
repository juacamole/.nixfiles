{ pkgs, ... }:
let
  # Shared launch configs for C and C++ (lldb-dap adapter).
  lldbConfigs = [
    {
      name = "Launch";
      type = "lldb"; # matches adapters.executables.lldb below
      request = "launch";
      program.__raw = ''
        function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end
      '';
      cwd.__raw = "function() return vim.fn.getcwd() end";
      stopOnEntry = false;
      args = [ ];
    }
    {
      name = "Launch (+args)";
      type = "lldb";
      request = "launch";
      program.__raw = ''
        function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end
      '';
      cwd.__raw = "function() return vim.fn.getcwd() end";
      stopOnEntry = false;
      args.__raw = ''
        function()
          return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
        end
      '';
    }
  ];
in
{
  programs.nixvim = {
    plugins = {
      dap = {
        enable = true;
        # lldb-dap ships with the lldb package already in home.packages.
        adapters.executables.lldb.command = "${pkgs.lldb}/bin/lldb-dap";
        configurations = {
          c = lldbConfigs;
          cpp = lldbConfigs;
        };
      };

      dap-ui.enable = true;
      dap-virtual-text.enable = true; # inline variable values during a session
    };

    # Auto open/close the dap-ui panels with the debug session.
    extraConfigLua = ''
      do
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      end
    '';
  };
}
