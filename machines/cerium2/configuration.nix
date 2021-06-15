{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  pkgs-unstable = import unstableTarball {
    config = config.nixpkgs.config;
  };
in {
  imports = [
    ./hardware-configuration.nix

    ../../modules/base-headless.nix
  ];

  boot.cleanTmpDir = true;

  networking.hostName = "cerium2";

  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;

  networking.firewall.allowPing = true;

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    pkgs.termite.terminfo
  ];

  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    package = pkgs-unstable.minecraft-server;  # 1.17
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Prohibit password auth in general. root has it disabled by default regardless.
  services.openssh.passwordAuthentication = false;

  programs.fish.enable = true;

  # Limit journald disk usage.
  services.journald.extraConfig = ''
    SystemMaxUse=25M
    SystemMaxFileSize=5M
  '';

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWFebTJiKlAumh63o4zvs0BsZCQpTYXN9Tzt6Znwb88FQhFffW7qUgqch1aOt2jobt6LpbE9mzQdNKjAsWjQWxJEOgWx/Sk9w1v3zJFKNSbdzCwZ8IwlYN16BIBpzf7suyjXcN/lVkzhXhfh/XnWJMgg69gd8s6nYPDFpCJhMX+rmrAe1pWM06LmKRF36o/zsdxAlYn6BFV4Hu4P/ArF1h29HkSRkPeAuuqFIrTNaWNdDQWJmmfgOtW7wovKhEXjn+ahCQcjDHmMEjSQpvS3EXuX27sUiXm1NuupVLM7sebinuJKLKKCcjzGegxROWFPJJtrjBSLDKllhjLda1dtqT archbox"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAq4ZG05caswrLQz/QoMcY2r35iWvCriRkpFB/eJGaK3 jonas@lanthanum"

      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDlE2lQu68L42TPXIh5+Ln/tO9joVSGzmjRPkxSCOBRaz9VBTQCQayt1lUeSZ29YpEfu3NOZNytSEa7R6av3bSqVNcKnK3lEtQtQQroRe1gdoswAjUgu4tGCzAVhH1xXOxZ0Q2pOah3brEOwDYc1WWzk0T2biW6/qtc3ZFTXMuem3TXRyP9cDd5LQvnboLwbco9UAssyOI9YlKg/ea8bWu05ZlWvX9uk/HbIyzqmN2Y2QSOgikz3Ad1jF8qOjwiyou+KRe5VfLlsoWhGm0KzjOrPi1LEB7zhF77gTmJxMABny1djySeydPZwJeCIFBrRg6CZJMucnWT9auuVMydCxObz0/YF1A9vkUov5zE2Jh5hvJAwfoSqz/kGLqHhKG4T0xuV1gHYEY/nKS0SwhrnjrEwUGn3ZeP0hk0O0MPqoaMbgWpNowfLGILx5DsRam7D/L8RjvYiQbWzFgpZU+MYJ2ep5qvlpOJBPMCM27FkZSpapwCzqEGnqiXSX1CRkOzQEc= jonas@yttrium"
    ];
    shell = pkgs.fish;
  };

  # This machine just runs daemons and only needs an administration user (root, defined above)
  users.mutableUsers = false;

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
}
