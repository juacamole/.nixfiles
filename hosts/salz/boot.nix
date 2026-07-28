{ ... }: {
  # Asahi / U-Boot chainloads systemd-boot from the EFI system partition.
  # Do NOT enable GRUB, and do NOT touch EFI variables on this machine.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # NOTE: boot.kernelPackages is intentionally NOT set here — the
  # apple-silicon-support module provides the Asahi kernel.

  # fnmode=2: top-row keys send media/brightness by default; Fn+F-key sends
  # the raw F-key. Matches macOS default and lets Hyprland bind the XF86
  # symbols directly without stealing Fn+F1/F2.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
}
