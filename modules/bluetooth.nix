{ config, pkgs, ... }:

{
  # Enable the full BlueZ suite
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };

  # Make blueman-mechanism available so blueman-applet works
  services.blueman.enable = true;

  # Make sure that if PulseAudio is used, the full package with BT support is used.
  hardware.pulseaudio = {
    package = pkgs.pulseaudioFull;
  };
}
