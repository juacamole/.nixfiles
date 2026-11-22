{ pkgs, ... }:
let
  askExecutable.__raw = ''
    function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end
  '';

  launch = {
    type = "lldb";
    request = "launch";
    program = askExecutable;
    cwd.__raw = "function() return vim.fn.getcwd() end";
    stopOnEntry = false;
  };

  lldbConfigs = [
    (launch // {
      name = "Launch";
      args = [ ];
    })
    (launch // {
      name = "Launch (+args)";
      args.__raw = ''
        function()
          return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
        end
      '';
    })
  ];

  map = key: module: call: desc: {
    mode = "n";
    key = "<leader>d${key}";
    action = "<cmd>lua require('${module}').${call}<cr>";
    options.desc = desc;
  };
in {
  programs.nixvim = {
    plugins = {
      dap = {
        enable = true;
        adapters.executables.lldb.command = "${pkgs.lldb}/bin/lldb-dap";
        configurations = {
          c = lldbConfigs;
          cpp = lldbConfigs;
        };
      };

      # Runs the python3 on PATH, so a dev shell's packages are importable.
      dap-python.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
    };

    # The dap-ui panels open and close with the debug session.
    extraConfigLua = ''
      do
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      end
    '';

    keymaps = [
      (map "b" "dap" "toggle_breakpoint()" "Toggle Breakpoint")
      (map "c" "dap" "continue()" "Continue / Start")
      (map "i" "dap" "step_into()" "Step Into")
      (map "o" "dap" "step_over()" "Step Over")
      (map "O" "dap" "step_out()" "Step Out")
      (map "r" "dap" "repl.toggle()" "Toggle REPL")
      (map "t" "dap" "terminate()" "Terminate")
      (map "u" "dapui" "toggle()" "Toggle UI")
    ];

    plugins.which-key.settings.spec = [
      { __unkeyed-1 = "<leader>d"; group = "Debug"; }
    ];
  };
}
