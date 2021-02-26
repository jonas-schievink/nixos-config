# GitHub Actions runners for Hardware-in-the-loop testing.

{ config, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.gha-hil-runners;
  runnerOptions = { ... }: {
    options = {

      name = mkOption {
        type = types.str;
        default = "gha-self-hosted";
        description = "Name to register the runner with.";
      };

      accessTokenFile = mkOption {
        type = types.path;
        description = ''
          Path to file containing `ACCESS_TOKEN=<Private Access Token>`. For security, this is not
          stored in the Nix store (which is world-readable), but passed directly to the container
          runtime, so unfortunately it has to start with `ACCESS_TOKEN=`.
        '';
      };

      repoUrl = mkOption {
        type = types.str;
        description = "Repository URL to register with";
        example = "https://github.com/octocat/repo";
      };

      usbSerial = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "Serial string of a USB device to forward to the runner.";
        example = "303233200A434E4B11002C00";
      };

      extraEnv = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = "Additional environment variables to set for the created container.";
        example = literalExample ''
          {
            DATABASE_HOST = "db.example.com";
            DATABASE_PORT = "3306";
          }
        '';
      };

      extraOptions = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Extra options for <command>${defaultBackend} run</command>.";
        example = literalExample ''
          ["--network=host"]
        '';
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When enabled, the container is automatically started on boot.
          If this option is set to false, the container has to be started on-demand via its service.
        '';
      };

    };
  };
in {

  imports = [
    ./rootless-containers.nix
  ];

  options.services.gha-hil-runners = mkOption {
    type = types.attrsOf (types.submodule runnerOptions);
    default = {};
    description = "GitHub Actions runners to install";
  };

  config = let
    mkContainer = name: runner: lib.mkMerge [{
      image = "myoung34/github-runner:latest";
      environment = lib.mkMerge [{
        RUNNER_NAME = runner.name;
        REPO_URL = runner.repoUrl;
      } runner.extraEnv];
      extraOptions = let
        expected = "ACCESS_TOKEN=";
        contents = builtins.readFile runner.accessTokenFile;
        start = builtins.substring 0 (builtins.stringLength expected) contents;
      in
        assert start == expected;
        [ "--env-file" (toString runner.accessTokenFile) ];
      groups = [ "gha-${name}" ];
      autoStart = runner.autoStart;
    } (lib.mkIf (runner.usbSerial != null) {
      extraOptions = [
        "--device=/dev/gha_${runner.usbSerial}"
      ];
    }) {
      extraOptions = runner.extraOptions;
    }];

    mkUdevRule = name: runner: if runner.usbSerial == null then
      ""
    else ''
      SUBSYSTEM=="usb", ATTRS{serial}=="${runner.usbSerial}", SYMLINK+="gha_$attr{serial}", GROUP="gha-${name}"
    '';
  in
    lib.mkIf (cfg != {}) {
      virtualisation.rootless-containers.containers = mapAttrs' (n: v: nameValuePair "gha-${n}" (mkContainer n v)) cfg;
      services.udev.extraRules = concatStringsSep "\n" (mapAttrsToList mkUdevRule cfg);
      users.groups = mapAttrs' (n: v: nameValuePair "gha-${n}" {}) cfg;
    };

}
