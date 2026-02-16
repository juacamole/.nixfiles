{ pkgs, ... }: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      forceInstall = true; 
    };
    systemd-boot.enable = false;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
