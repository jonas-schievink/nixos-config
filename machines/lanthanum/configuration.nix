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
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable exFAT support
  boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];

  networking.hostName = "lanthanum";
  networking.networkmanager.enable = true;

  # the firewall is often very verbose in dmesg
  networking.firewall.logRefusedConnections = false;

  # Select internationalisation properties.
  i18n = {
    consoleFont   = "latarcyrheb-sun32";  # largest font in kbd pkg (for HiDPI)
    consoleKeyMap = "de-latin1-nodeadkeys";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Berlin";

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

    # graphical utils
    glxinfo
    xdotool
    xorg.xdpyinfo xorg.xev xorg.xmodmap xorg.xdriinfo xorg.xrandr xorg.xprop
    xorg.xwininfo
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # List all packages whose udev rules to install.
  # Installs everything in that package's /etc/udev/rules.d and /lib/udev/rules.d
  services.udev.packages = with pkgs; [
    openocd dfu-util stlink
  ];
  # Install extra `.rules` files
  services.udev.extraRules = let
    loadRules = path: ''
      # ${path}
      ${builtins.readFile path}
    '';
    paths = [
      ./99-jlink.rules
    ];
  in pkgs.lib.concatStrings (map loadRules paths);

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pcscd.enable = true;
  hardware.nitrokey.enable = true;

  services.hardware.bolt.enable = true;

  services.fwupd.enable = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Add OpenGL packages
  hardware.opengl = {
    extraPackages = with pkgs; [vaapiIntel intel-media-driver];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    dpi = 192;

    layout = "de";
    xkbVariant = "nodeadkeys";
    autoRepeatDelay = 220;
    autoRepeatInterval = 25;  # 40 Hz
  };

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;
    naturalScrolling = true;  # touchpad
  };

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
  };

  # PostgreSQL database for development
  services.postgresql = {
    enable = true;
    # We trust anything connecting to localhost or via the Unix socket.
    authentication = pkgs.lib.mkForce ''
      local all all              trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jonas = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "dialout" "input" "nitrokey" ];
    shell = pkgs.fish;
  };

  # TODO mutableUsers = false (but this disallows changing passwords!)
  security.sudo.extraConfig = ''
    # Do not time out the password prompt
    Defaults passwd_timeout=0
  '';

  # Auto-GC to prevent the drive from filling up
  # TODO does this work when the system isn't online at 3:15?
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  nix.extraOptions = ''
    # Cache downloaded tarballs/repos/source archives for about a month.
    # The default is one hour, which is bad when I don't have internet.
    tarball-ttl = 2630000
  '';

  # Allow installation of non-free software such as Slack
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?
}
