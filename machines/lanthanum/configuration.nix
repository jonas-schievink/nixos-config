# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    # Use an absolute path since this is stored on the machine, not in the
    # config repo.
    /etc/nixos/hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/udev-rules
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # Allow installation of bootloader into EFI vars.
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "lanthanum";
  networking.networkmanager.enable = true;

  i18n.consoleFont = "latarcyrheb-sun32";  # largest font in kbd pkg (for HiDPI)

  time.timeZone = "Europe/Berlin";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pcscd.enable = true;
  hardware.nitrokey.enable = true;

  services.hardware.bolt.enable = true;

  services.fwupd.enable = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jonas = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "dialout" "input" "nitrokey" "plugdev" "vboxusers" ];
    shell = pkgs.fish;
  };

  # TODO mutableUsers = false (but this disallows changing passwords!)

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?
}
