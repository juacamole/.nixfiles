{ ... }: {
  # Asahi / U-Boot chainloads systemd-boot from the EFI system partition.
  # Do NOT enable GRUB, and do NOT touch EFI variables on this machine.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # NOTE: boot.kernelPackages is intentionally NOT set here — the
  # apple-silicon-support module provides the Asahi kernel.
}
