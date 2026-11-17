{ ... }: {
  # U-Boot chainloads systemd-boot. No GRUB, and never touch EFI variables here.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Top row sends media keys; Fn+F-key sends the F-key.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
}
