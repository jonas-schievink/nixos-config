# Installs and autostarts the Xfce 4 Notification Daemon on graphical login.

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.xfce.xfce4-notifyd ];

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
