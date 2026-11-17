{ pkgs, lib, inputs, ... }: {
  # Every value here was measured on this machine; the reasoning is in docs/llm.md.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    user = "ollama";
    group = "ollama";
    home = "/var/lib/ollama";

    environmentVariables = {
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_LOAD_TIMEOUT = "15m";
      OLLAMA_CONTEXT_LENGTH = "262144";
      # Vulkan heap in bytes (55 GiB); the driver defaults to half of RAM.
      HK_SYSMEM = "59055800320";
    };
  };

  # The module hardcodes DynamicUser, which hides the model store under /var/lib/private.
  systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  environment.systemPackages = [
    (import ./llama-cpp.nix { inherit pkgs; })
    inputs.allam.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Experiment: re-enables GPU compute preemption, which the Asahi kernel
  # turns off. Watch `journalctl -k` for GPU faults.
  boot.kernelParams = [ "asahi.debug_flags=0x1000000000000" ];
}
