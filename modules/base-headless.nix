# NixOS base configuration included by all machines.
# This configures things that should be the same on *all* machines, desktops,
# laptops, and servers alike.

{ config, pkgs, lib, ... }:

{
  # Enable exFAT support
  boot.extraModulePackages = lib.mkIf
    (lib.versionOlder config.boot.kernelPackages.kernel.version "5.8")
    [ config.boot.kernelPackages.exfat-nofuse ];

  # The firewall logging is very verbose in dmesg, tone it down a bit
  networking.firewall.logRefusedConnections = false;

  networking.hosts = {
    "130.255.76.128" = ["cerium"];  # public IP

    # VPN IPs
    "10.11.12.1" = ["cerium.home"];
    "10.11.12.2" = ["archbox.home"];
    "10.11.12.3" = ["lanthanum.home"];

    # The .home TLD is used as per:
    # https://www.icann.org/resources/board-material/resolutions-2018-02-04-en#2.c
  };

  console.keyMap = "de-latin1-nodeadkeys";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.addresses = true;
  };

  # System-level packages. Mostly contains system management and debugging
  # utils.
  # $ nix search <NAME>
  environment.systemPackages = with pkgs; [
    # base utilities
    utillinux binutils neovim file

    # hardware info and debugging utils
    usbutils pciutils lsof nvme-cli smartmontools hdparm htop powertop
    tpm2-tools thunderbolt

    # network utils
    wget curl git gitAndTools.gh subversion ethtool
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
