{ config, pkgs, ... }:

{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.gha-runner = {
    image = "myoung34/github-runner:latest";
    autoStart = false;
    environment = {
      RUNNER_NAME = "gha-self-hosted";
      ACCESS_TOKEN = pkgs.lib.removeSuffix "\n" (builtins.readFile ./gha-runner.key);
      REPO_URL = "https://github.com/jonas-schievink/bxcan-ci";
    };
    extraOptions = [
      "--device=/dev/probe_303233200A434E4B11002C00"
    ];
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="da42", SYMLINK+="probe_$attr{serial}"
  '';
}
