{ config, options, lib, pkgs, ... }:

with lib;
let
  cfg = config.virtualisation.rootless-containers;
  proxy_env = config.networking.proxy.envVars;

  defaultBackend = options.virtualisation.rootless-containers.backend.default;

  containerOptions =
    { ... }: {

      options = {

        image = mkOption {
          type = with types; str;
          description = "OCI image to run.";
          example = "library/hello-world";
        };

        imageFile = mkOption {
          type = with types; nullOr package;
          default = null;
          description = ''
            Path to an image file to load instead of pulling from a registry.
            If defined, do not pull from registry.

            You still need to set the <literal>image</literal> attribute, as it
            will be used as the image name for docker to start a container.
          '';
          example = literalExample "pkgs.dockerTools.buildDockerImage {...};";
        };

        cmd = mkOption {
          type =  with types; listOf str;
          default = [];
          description = "Commandline arguments to pass to the image's entrypoint.";
          example = literalExample ''
            ["--port=9000"]
          '';
        };

        entrypoint = mkOption {
          type = with types; nullOr str;
          description = "Override the default entrypoint of the image.";
          default = null;
          example = "/bin/my-app";
        };

        environment = mkOption {
          type = with types; attrsOf str;
          default = {};
          description = "Environment variables to set for this container.";
          example = literalExample ''
            {
              DATABASE_HOST = "db.example.com";
              DATABASE_PORT = "3306";
            }
        '';
        };

        log-driver = mkOption {
          type = types.str;
          default = "journald";
          description = ''
            Logging driver for the container.  The default of
            <literal>"journald"</literal> means that the container's logs will be
            handled as part of the systemd unit.

            For more details and a full list of logging drivers, refer to respective backends documentation.

            For Docker:
            <link xlink:href="https://docs.docker.com/engine/reference/run/#logging-drivers---log-driver">Docker engine documentation</link>

            For Podman:
            Refer to the docker-run(1) man page.
          '';
        };

        ports = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            Network ports to publish from the container to the outer host.

            Valid formats:

            <itemizedlist>
              <listitem>
                <para>
                  <literal>&lt;ip&gt;:&lt;hostPort&gt;:&lt;containerPort&gt;</literal>
                </para>
              </listitem>
              <listitem>
                <para>
                  <literal>&lt;ip&gt;::&lt;containerPort&gt;</literal>
                </para>
              </listitem>
              <listitem>
                <para>
                  <literal>&lt;hostPort&gt;:&lt;containerPort&gt;</literal>
                </para>
              </listitem>
              <listitem>
                <para>
                  <literal>&lt;containerPort&gt;</literal>
                </para>
              </listitem>
            </itemizedlist>

            Both <literal>hostPort</literal> and
            <literal>containerPort</literal> can be specified as a range of
            ports.  When specifying ranges for both, the number of container
            ports in the range must match the number of host ports in the
            range.  Example: <literal>1234-1236:1234-1236/tcp</literal>

            When specifying a range for <literal>hostPort</literal> only, the
            <literal>containerPort</literal> must <emphasis>not</emphasis> be a
            range.  In this case, the container port is published somewhere
            within the specified <literal>hostPort</literal> range.  Example:
            <literal>1234-1236:1234/tcp</literal>

            Refer to the
            <link xlink:href="https://docs.docker.com/engine/reference/run/#expose-incoming-ports">
            Docker engine documentation</link> for full details.
          '';
          example = literalExample ''
            [
              "8080:9000"
            ]
          '';
        };

        user = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            Override the username or UID (and optionally groupname or GID) used
            in the container.
          '';
          example = "nobody:nogroup";
        };

        volumes = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            List of volumes to attach to this container.

            Note that this is a list of <literal>"src:dst"</literal> strings to
            allow for <literal>src</literal> to refer to
            <literal>/nix/store</literal> paths, which would be difficult with an
            attribute set.  There are also a variety of mount options available
            as a third field; please refer to the
            <link xlink:href="https://docs.docker.com/engine/reference/run/#volume-shared-filesystems">
            docker engine documentation</link> for details.
          '';
          example = literalExample ''
            [
              "volume_name:/path/inside/container"
              "/path/on/host:/path/inside/container"
            ]
          '';
        };

        workdir = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "Override the default working directory for the container.";
          example = "/var/lib/hello_world";
        };

        dependsOn = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            Define which other containers this one depends on. They will be added to both After and Requires for the unit.

            Use the same name as the attribute under <literal>virtualisation.rootless-containers.containers</literal>.
          '';
          example = literalExample ''
            virtualisation.rootless-containers.containers = {
              node1 = {};
              node2 = {
                dependsOn = [ "node1" ];
              }
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

        #[rootless]
        groups = mkOption {
          type = with types; listOf str;
          default = [];
          description = "Extra groups to add the rootless user to";
          example = literalExample ''
            ["plugdev"]
          '';
        };
      };
    };

  #[rootless]
  mkService = index: name: container: let
    dependsOn = map (x: "${cfg.backend}-${x}.service") container.dependsOn;
    subUidStart = (index * 100000) + 1500000000;  # 1.5 billion offset from NixOS-assigned IDs
    # (this is also the start of the subgid range, not just subuid)
  in {
    wantedBy = [] ++ optional (container.autoStart) "multi-user.target";
    after = lib.optionals (cfg.backend == "docker") [ "docker.service" "docker.socket" ]
      #[rootless] added network dependency (podman itself needs that to pull the image)
      ++ ["network-online.target"]
      ++ dependsOn;
    requires = dependsOn;
    environment = proxy_env;

    path =
      if cfg.backend == "docker" then [ config.virtualisation.docker.package ]
      else if cfg.backend == "podman" then [ config.virtualisation.podman.package ]
      else throw "Unhandled backend: ${cfg.backend}";

    preStart = ''
      ${cfg.backend} rm -f ${name} || true
      ${optionalString (container.imageFile != null) ''
        ${cfg.backend} load -i ${container.imageFile}
        ''}
      '';

    script = concatStringsSep " \\\n  " ([
      "exec ${cfg.backend} run"
      "--rm"
      "--name=${escapeShellArg name}"
      "--log-driver=${container.log-driver}"
    ] ++ optional (container.entrypoint != null)
      "--entrypoint=${escapeShellArg container.entrypoint}"
      ++ (mapAttrsToList (k: v: "-e ${escapeShellArg k}=${escapeShellArg v}") container.environment)
      ++ map (p: "-p ${escapeShellArg p}") container.ports
      ++ optional (container.user != null) "-u ${escapeShellArg container.user}"
      ++ map (v: "-v ${escapeShellArg v}") container.volumes
      ++ optional (container.workdir != null) "-w ${escapeShellArg container.workdir}"
      #[rootless]
      ++ [ "--uidmap" "0:${toString subUidStart}:65536" ]
      ++ [ "--gidmap" "0:${toString subUidStart}:65536" ]
      #[/rootless]
      ++ map escapeShellArg container.extraOptions
      ++ [container.image]
      ++ map escapeShellArg container.cmd
    );

    preStop = "[ $SERVICE_RESULT = success ] || ${cfg.backend} stop ${name}";
    postStop = "${cfg.backend} rm -f ${name} || true";

    serviceConfig = {
      #[rootless] commented out because they eat important podman errors! (this does duplicate
      # container output though)
      #StandardOutput = "null";
      #StandardError = "null";

      ### There is no generalized way of supporting `reload` for docker
      ### containers. Some containers may respond well to SIGHUP sent to their
      ### init process, but it is not guaranteed; some apps have other reload
      ### mechanisms, some don't have a reload signal at all, and some docker
      ### images just have broken signal handling.  The best compromise in this
      ### case is probably to leave ExecReload undefined, so `systemctl reload`
      ### will at least result in an error instead of potentially undefined
      ### behaviour.
      ###
      ### Advanced users can still override this part of the unit to implement
      ### a custom reload handler, since the result of all this is a normal
      ### systemd service from the perspective of the NixOS module system.
      ###
      # ExecReload = ...;
      ###

      TimeoutStartSec = 0;
      TimeoutStopSec = 120;
      Restart = "always";
    };
  };

in {
  #[rootless] commented out due to conflicts
  #imports = [
  #  (
  #    lib.mkChangedOptionModule
  #    [ "docker-containers"  ]
  #    [ "virtualisation" "rootless-containers" ]
  #    (oldcfg: {
  #      backend = "docker";
  #      containers = lib.mapAttrs (n: v: builtins.removeAttrs (v // {
  #        extraOptions = v.extraDockerOptions or [];
  #      }) [ "extraDockerOptions" ]) oldcfg.docker-containers;
  #    })
  #  )
  #];

  options.virtualisation.rootless-containers = {

    backend = mkOption {
      type = types.enum [ "podman" "docker" ];
      default =
        # TODO: Once https://github.com/NixOS/nixpkgs/issues/77925 is resolved default to podman
        # if versionAtLeast config.system.stateVersion "20.09" then "podman"
        # else "docker";
        "podman"; #[rootless] changed to podman
      description = "The underlying Docker implementation to use.";
    };

    containers = mkOption {
      default = {};
      type = types.attrsOf (types.submodule containerOptions);
      description = "OCI (Docker) containers to run as systemd services.";
    };

  };

  config = lib.mkIf (cfg.containers != {}) (lib.mkMerge [
    #[rootless]
    (let
      containerList = mapAttrsToList (n: v: nameValuePair n v) cfg.containers;
      services = imap0 (i: nvp: nameValuePair "${cfg.backend}-${nvp.name}" (mkService i nvp.name nvp.value)) containerList;
    in {
      systemd.services = listToAttrs services;
    })
    (lib.mkIf (cfg.backend == "podman") {
      virtualisation.podman.enable = true;
    })
    (lib.mkIf (cfg.backend == "docker") {
      virtualisation.docker.enable = true;
    })
  ]);

}
