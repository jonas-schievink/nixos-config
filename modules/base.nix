# NixOS base configuration for "headfull" user-facing systems with graphical
# capabilities (ie. laptops or desktops).

{ config, pkgs, ... }:

{
  imports = [
    ./base-headless.nix
    ./bluetooth.nix
  ];

  # Install additional system programs
  environment.systemPackages = with pkgs; [
    # graphical utils
    glxinfo
    xdotool
    xorg.xdpyinfo xorg.xev xorg.xmodmap xorg.xdriinfo xorg.xrandr xorg.xprop
    xorg.xwininfo
  ];

  fonts = {
    enableDefaultFonts = false;

    fonts = [
      pkgs.font-awesome_4   # icon font
      pkgs.powerline-fonts  # Powerline-patched monospace fonts
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk
      pkgs.noto-fonts-emoji
      pkgs.noto-fonts-extra
    ];

    fontconfig.defaultFonts = {
      monospace = [ "Noto Mono for Powerline" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Add OpenGL packages
  hardware.opengl = {
    extraPackages = with pkgs; [vaapiIntel intel-media-driver intel-ocl];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    dpi = 192;

    layout = "de";
    xkbVariant = "nodeadkeys";
    autoRepeatDelay = 220;
    autoRepeatInterval = 25;  # 40 Hz

    serverLayoutSection = ''
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime"     "0"
      Option "BlankTime"   "0"
    '';
  };

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    qemuRunAsRoot = false;
  };
}
