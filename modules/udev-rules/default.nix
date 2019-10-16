# Provides a custom set of udev rules, for hardware I use often (mostly debug
# probes and dev kits).

{ config, pkgs, ... }:

{
  # Installs everything in that package's /etc/udev/rules.d and /lib/udev/rules.d
  services.udev.packages = with pkgs; [
    openocd dfu-util stlink yubikey-personalization acpilight
  ];
  # Install extra `.rules` files
  services.udev.extraRules = let
    loadRules = path: ''
      # ${path}
      ${builtins.readFile path}
    '';
    paths = [
      ./99-jlink.rules
      ./99-stm-dfu.rules
      ./99-mcp2210.rules
    ];
  in pkgs.lib.concatStrings (map loadRules paths);
}
