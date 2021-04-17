# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/base-headless.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.enableContainers = false;
  boot.initrd.checkJournalingFS = false;

  networking.hostName = "cerium";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens3 = {
    ipv4 = {
      addresses = [
        { address = "130.255.76.128"; prefixLength = 24; }
      ];
    };
    ipv6 = {
      addresses = [
        { address = "2a02:e00:ffec:881::1"; prefixLength = 48; }
      ];
    };
  };
  networking.defaultGateway = "130.255.76.1";
  networking.defaultGateway6 = "2a02:e00:ffec::1";
  networking.nameservers = [ "9.9.9.9" "8.8.8.8" "8.8.4.4" ];

  # VPN setup
  # (this is a wireguard "supernode" that does not by itself participate in the VPN; it is only for
  # routing and has a static and public IP)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };
  networking.wireguard.enable = true;
  networking.wireguard.interfaces.wg0 = {
    ips = ["10.11.12.1/24"];
    listenPort = 51820;
    privateKeyFile = toString ./wireguard.key;
    generatePrivateKeyFile = true;
    peers = [
      {
        # archbox
        publicKey = "0Ddcfeyq6AmFNnwVeNDobURaX1uXoiawGiEBa7MuVQ8=";
        allowedIPs = ["10.11.12.2/32"];
      }
      {
        # lanthanum
        publicKey = "4PPLl1dfvbuwHAJjjBzeDWlM66TKCGYCdzPb+ppphRM=";
        allowedIPs = ["10.11.12.3/32"];
      }
      {
        # yttrium
        publicKey = "0MIHnjztjoUf+QC6RMp1rgZANtVc1yu4Fi3kd9wgFU0=";
        allowedIPs = ["10.11.12.4/32"];
      }
      {
        # phone
        publicKey = "HJRD64Zu+cBn3hOuBHwHwsZK4+xKNrbeqzL0ywexuRs=";
        allowedIPs = ["10.11.12.100/32"];
      }
    ];
  };

  security.acme.acceptTerms = true;
  security.acme.email = "jonasschievink+acme@gmail.com";
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    virtualHosts = {
      "gehorche.computer" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          root = pkgs.buildEnv {
            name = "webroot-gehorche.computer";
            paths = [ ./www ];
          };
        };
      };
    };
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    pkgs.termite.terminfo
  ];

  # Limit journald disk usage, which is in short supply here. It still uses too much RAM.
  services.journald.extraConfig = ''
    SystemMaxUse=25M
    SystemMaxFileSize=5M
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # Prohibit password auth in general. root has it disabled by default regardless.
  services.openssh.passwordAuthentication = false;

  programs.fish.enable = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

}
