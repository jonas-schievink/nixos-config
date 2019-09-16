# NixOS base configuration included by all machines.
# This configures things that should be the same on *all* machines, desktops,
# laptops, and servers alike.

{ config, pkgs, ... }:

{
  # Enable exFAT support
  boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];

  # The firewall logging is very verbose in dmesg, tone it down a bit
  networking.firewall.logRefusedConnections = false;

  i18n = {
    consoleKeyMap = "de-latin1-nodeadkeys";
    defaultLocale = "en_US.UTF-8";
  };

  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # System-level packages. Mostly contains system management and debugging
  # utils.
  # $ nix search <NAME>
  environment.systemPackages = with pkgs; [
    # base utilities
    utillinux binutils neovim

    # hardware info and debugging utils
    usbutils pciutils lsof nvme-cli smartmontools hdparm htop powertop
    tpm2-tools thunderbolt

    # network utils
    git subversion wget curl
  ];

  security.sudo.extraConfig = ''
    # Do not time out the password prompt
    Defaults passwd_timeout=0
  '';

  # Allow installation of non-free software such as Slack
  nixpkgs.config.allowUnfree = true;

  # Auto-GC to prevent the drive from filling up
  # TODO does this work when the system isn't online at 3:15?
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  nix.extraOptions = ''
    # Cache downloaded tarballs/repos/source archives for about a month.
    # The default is one hour, which is bad when I don't have internet.
    tarball-ttl = 2630000
  '';
}
