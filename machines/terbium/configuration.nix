{ config, pkgs, ... }:

let
  makeGHARunner = { runnerName ? "gha-self-hosted", pakFile, repoUrl, probeSerial }: {
    image = "myoung34/github-runner:latest";
    environment = {
      RUNNER_NAME = runnerName;
      ACCESS_TOKEN = pkgs.lib.removeSuffix "\n" (builtins.readFile pakFile);
      REPO_URL = repoUrl;
    };
    extraOptions = [
      "--device=/dev/probe_${probeSerial}"
    ];
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/base-headless.nix
  ];

  boot.loader.timeout = 5;
  boot.loader.grub.enable = false;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 4;  # Raspberry Pi 4

  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  hardware.enableRedistributableFirmware = true;

  boot.enableContainers = false;
  boot.initrd.checkJournalingFS = false;

  networking.hostName = "terbium";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

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

  ### GitHub Actions runner setup ###
  # The purpose of the runners is to run hardware-in-the-loop tests that talk to external hardware.
  # This registers a udev rule that creates unique symlinks to the USB device nodes that incorporate
  # the USB serial number. For example: `/dev/probe_303233200A434E4B11002C00`
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="da42", SYMLINK+="probe_$attr{serial}"
  '';
  # Set up a container per repo to install a runner in.
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.gha-bxcan = makeGHARunner {
    pakFile = ./gha-bxcan.key;
    repoUrl = "https://github.com/jonas-schievink/bxcan-ci";
    probeSerial = "303233200A434E4B11002C00";
  };

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
  system.stateVersion = "20.09"; # Did you read the comment?

}
