# Installs and autostarts the Xfce 4 Notification Daemon on graphical login.

{ config, lib, pkgs, ... }:

let
  notifyd = pkgs.xfce.xfce4-notifyd;
  # The package has its own desktop item, but it uses `OnlyShowIn=XFCE`, which is wrong, so we
  # create our own.
  desktop-item = pkgs.makeDesktopItem {
    name = "xfce4-notifyd-config-custom";
    exec = "${notifyd}/bin/xfce4-notifyd-config";
    desktopName = "Configure Xfce4 Notification Daemon";
  };
in {
  home.packages = [ notifyd desktop-item ];

  systemd.user.services.notifyd = {
    Unit = {
      Description = "Xfce 4 Notification Daemon";
    };
    Service = {
      ExecStart = "${pkgs.xfce.xfce4-notifyd.out}/lib/xfce4/notifyd/xfce4-notifyd";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # TODO: Config generation etc.
}
