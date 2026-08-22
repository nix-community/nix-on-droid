{ config
, lib
, pkgs
, ...
}:
let
  inherit (builtins)
    toString
    ;

  inherit (lib)
    attrByPath
    attrValues
    concatStringsSep
    filterAttrs
    getExe
    literalExpression
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    optionalString
    optionals
    typeOf
    ;

  inherit (lib.types)
    attrsOf
    int
    either
    nonEmptyStr
    nullOr
    package
    path
    submodule
    ;

  inherit (pkgs)
    makeWrapper
    runit
    writeTextFile
    ;

  inherit (pkgs.stdenv)
    mkDerivation
    ;

  mkService =
    { name, ... }:
    let
      control = mkOption {
        description = ''
          [man rusv -- Control](https://smarden.org/runit1/runsv.8#sect3)

          Services have a named pipe under `''${config.runit.settings.environment.svdir}/NAME/supervise/control`
          Logs have a named pipe under `''${config.runit.settings.environment.svdir}/NAME/log/supervise/control`

          These named pipes when written to with a given control character may call associated executable.
        '';

        example = literalExpression ''
          ## Service control
          runit.services.NAME.control.u = '''
            #!''${pkgs.runtimeShell}

            _exe_basename="''${pkgs.coreutils.outPath}/bin/basename";
            _exe_dirname="''${pkgs.coreutils.outPath}/bin/dirname";

            _name="$("$_exe_basename" "$("$_exe_dirname" "$PWD")")";

            echo "control/u called for: $_name";
          '''

          ## Log control
          runit.services.NAME.log.control.u = '''
            #!''${pkgs.runtimeShell}

            _exe_basename="''${pkgs.coreutils.outPath}/bin/basename";
            _exe_dirname="''${pkgs.coreutils.outPath}/bin/dirname";

            _parent="$("$_exe_basename" "$("$_exe_dirname" "$PWD")")";
            _name="$("$_exe_basename" "$_parent")";

            echo "control/u called for: $_name/log";
          '''
        '';

        default = { };
        type = submodule {
          options = {
            u = mkOption {
              description = ''
                Up. If the service is not running, start it. If the sesrvice stops, restart it.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            d = mkOption {
              description = ''
                Down. If the service is running, send it a TERM signal. If `./run` exits, start `./finish` if it exists. After it stops, do not restart service.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            o = mkOption {
              description = ''
                Once. If the service is not running, start it. Do not restart it if it stops.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            p = mkOption {
              description = ''
                Pause. If the service is running, send it a STOP signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            c = mkOption {
              description = ''
                Continue. If the service is running, send it a CONT signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            h = mkOption {
              description = ''
                Hangup. If the service is running, send it a HUP signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            a = mkOption {
              description = ''
                Alarm. If the service is running, send it a ALRM signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            i = mkOption {
              description = ''
                Interrupt. If the service is running, send it a INT signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            q = mkOption {
              description = ''
                Quit. If the service is running, send it a QUIT signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            "1" = mkOption {
              description = ''
                If the service is running, send it a USR1 signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            "2" = mkOption {
              description = ''
                If the service is running, send it a USR2 signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            k = mkOption {
              description = ''
                Kill. If the service is running, send it a KILL signal.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            x = mkOption {
              description = ''
                Exit. If the service is running, send it a TERM signal.

                Aliase of `e`, check `e` for more documentation and examples.
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
            e = mkOption {
              description = ''
                Exit. If the service is running, send it a TERM signal.
                Aliase of `x`

                Do not restart the service. If the service is down, and no log service exists, `runsv` exits.

                If the service is down and a log service exits, `runsv` closes the standard input of the log service, and waits for it to terminate.

                If the log sservice is down, `runsv` exits.

                This command is ignored if it is given to the `service/log/supervise/control`

                Example: to send a TERM signal to the socklog-unix service, either do `runsvctrl term ''${runit.settings.environment.svdir}/socklog-unix`

                or

                `echo -n t >''${runit.settings.environment.svdir}/socklog-unix/supervise/control`
              '';
              type = nullOr nonEmptyStr;
              default = null;
            };
          };
        };
      };
    in
    {
      options = {
        enable = mkEnableOption "Enable named service executables";

        package = mkOption {
          type = nullOr package;
          description = "Package to have `runit` monitor/start/stop";
        };

        svlogd = mkOption {
          description = ''
            See: https://smarden.org/runit/svlogd.8
          '';

          example = literalExpression ''
            See: https://smarden.org/runit/svlogd.8

            runit.services.NAME.svlogd = {
              enable = true;
              config = '''
                # Max file size
                s1000000
                # Number of log files to keep
                n10
                # Minimum number of old log files to maintain, must be less than `n`
                N10
                # Max age in seconds of current log file before rotating
                t41968
                # ...
              ''';
            };
          '';

          default = { };
          type = submodule {
            options = {
              enable = mkEnableOption "Enable svlogd for named service";

              config = mkOption {
                description = ''
                  May be multi-line string defining configurations, or path to preexisting configuration file

                  See: https://smarden.org/runit/svlogd.8#config
                '';
                default = null;
                type = nullOr (either nonEmptyStr path);
              };
            };
          };
        };

        execute = mkOption {
          description = ''
            Executables that may be called for starting, stopping, logging, and control signals of named service.
          '';

          type = submodule {
            options = {
              inherit control;

              run = mkOption {
                description = "Script that `sv` will call for starting service";

                example = literalExpression ''
                  runit.services.sshd.log = writeScriptBin "service-sshd-run" '''
                    #!''${pkgs.runtimeShell}

                    ''${pkgs.openssh}/bin/ssh-keygen -Af ''${config.build.installationDir}

                    mkdir -p ''${builtins.dirOf cfg.settings.PidFile}

                    exec ''${pkgs.openssh}/bin/sshd -f "''${config.environment.etc."ssh/sshd_config".source}" -De 2>&1
                  '''
                '';

                type = package;
              };

              check = mkOption {
                description = ''
                  Executable `sv` will call to check service is in given up/down state

                  See: https://smarden.org/runit/sv.8#additional-commands
                '';

                example = literalExpression ''
                  runit.services.sshd.check = writeScriptBin "service-sshd-check" '''
                    #!''${pkgs.runtimeShell}

                    printf 'service-sshd-check called';
                    env;
                    printf '%s\n' "''${@}";
                  '''
                '';

                type = package;
              };

              finish = mkOption {
                description = "Script that `sv` will call for stopping service";

                example = literalExpression ''
                  runit.services.sshd.log = writeScriptBin "service-sshd-finish" '''
                    #!''${pkgs.runtimeShell}

                    _exe_basename="''${pkgs.coreutils.outPath}/bin/basename";
                    _exe_dirname="''${pkgs.coreutils.outPath}/bin/dirname";

                    _name="$("$_exe_basename" "$("$_exe_dirname" "$PWD")")";

                    env;
                    echo "FINISED: _name -> $_name";
                  '''
                '';

                type = nullOr package;
                default = null;
              };

              log = mkOption {
                default = { };
                type = submodule {
                  options = {
                    inherit control;

                    run = mkOption {
                      description = ''
                        Script that `sv` will call for logging service.

                        See: https://smarden.org/runit/svlogd.8
                      '';

                      example = literalExpression ''
                        runit.services.sshd.log.run = writeScriptBin "service-sshd-log-run" '''
                          #!''${pkgs.runtimeShell}

                          exec "''${config.runit.package.outPath}/bin/svlogd" -tt "''${config.runit.settings.environment.svdir}/__NAME__";
                        '''
                      '';

                      type = nullOr package;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

  cfg = config.runit;
in
{
  options.runit = {
    enable = mkEnableOption "Enable runit configuration management";

    package = mkOption {
      description = ''
        Package that will be used with module and modified to include `config.runit.settings.environment.svdir`
      '';

      example = literalExpression ''
        package = pkgs.runit.overrideAttrs (oldAttrs: { ... });
      '';

      default = runit;
      type = package;
    };

    settings = mkOption {
      description = "";

      example = literalExpression ''
        runit.settings = {
          environment = {
            svdir = "''${config.build.installationDir}/var/service";
            logdir = "''${config.build.installationDir}/var/log";
            svwait = 7;
          };
        };
      '';

      default = { };
      type = submodule {
        options = {
          environment = mkOption {
            description = ''
              Environment variables that will be set via `wrapProgram` on all `''${config.package.outPath}/bin` executables
            '';

            default = { };
            type = submodule {
              options = {
                svdir = mkOption {
                  description = ''
                    Where files in `config.runit.service.NAME` will be linked to for `runit`
                  '';
                  type = nonEmptyStr;
                  default = "${config.build.installationDir}/var/service";
                };

                logdir = mkOption {
                  description = ''
                    Where logs in `config.runit.service.NAME` will be read/written for `runit`

                    TODO: double-check this is correct!
                  '';
                  type = nonEmptyStr;
                  default = "${config.build.installationDir}/var/log";
                };

                svwait = mkOption {
                  description = ''
                    See: https://manpages.debian.org/unstable/runit/sv.8.en.html#SVWAIT
                  '';
                  type = nullOr int;
                  default = null;
                };
              };
            };
          };

          init = mkOption {
            description = ''
              WARNING: untested!

              See: https://smarden.org/runit/replaceinit
            '';

            example = literalExpression ''
              runit.settings.init = {
                enable = true;

                dir = "''${config.build.installationDir}/etc/runit";

                getty-5.dir = "''${config.build.installationDir}/sv/getty-5";

                executables = {
                 "1" = writeScriptBin "runnit-system-boot" '''
                   # ...
                 ''';

                 "2" = writeScriptBin "runnit-system-run" '''
                   # ...
                 ''';

                 "2" = writeScriptBin "runnit-system-shutdown" '''
                   # ...
                 ''';
                };
              };
            '';

            default = { };
            type = submodule {
              options = {
                enable = mkEnableOption "Enable using runit as system init";

                description = ''
                  WARNING: untested!

                  See: https://smarden.org/runit/replaceinit
                '';

                dir = mkOption {
                  description = ''
                    Directory `sysvinit` checks for system booting, running, and shutdown
                  '';

                  example = literalExpression ''
                    runit.settings.init.dir = "''${config.build.installationDir}/etc/runit";
                  '';

                  type = nonEmptyStr;
                  default = "${config.build.installationDir}/etc/runit";
                };

                executables = mkOption {
                  type = submodule {
                    options = {
                      "1" = mkOption {
                        description = ''
                          System booting executable
                        '';
                        # example = literalExpression ''
                        # '';
                        type = nullOr package;
                        default = null;
                      };

                      "2" = mkOption {
                        description = ''
                          System running executable
                        '';
                        type = nullOr package;
                        default = null;
                      };

                      "3" = mkOption {
                        description = ''
                          System shutdown executable
                        '';
                        type = nullOr package;
                        default = null;
                      };

                      ctrlaltdel = mkOption {
                        description = ''
                          Handle ctrl-alt-del keyboard request
                        '';
                        type = nullOr package;
                        default = null;
                      };
                    };
                  };
                };

                getty-5 = mkOption {
                  description = ''
                    WARNING: untested!

                    See: https://github.com/NixOS/nixpkgs/blob/8c91a71d13451abc40eb9dae8910f972f979852f/nixos/modules/services/ttys/getty.nix
                  '';
                  example = ''
                    runit.settings.init.getty-5.service = {
                      enable = true;
                      package = lib.getExe' pkgs.util-linux "agetty";
                      # ...
                    };
                  '';
                  type = attrsOf (submodule (inputs: mkService (inputs // { name = "service"; })));
                };
              };
            };
          };

          ## TODO: Find less hacky way of avoiding rebuild from source
          packageWrapped = mkOption {
            description = ''
              Internal hacky mkDerivation modification used to avoid re-building `runit.package` from source
            '';

            example = literalExpression ''
              package = pkgs.runit.overrideAttrs (oldAttrs: { ... });
            '';

            default = mkDerivation {
              inherit (cfg.package) src;
              name = "NoD-wrapped-${cfg.package.pname}";
              version = "${cfg.package.version}-NoD-wrapped";
              nativeBuildInputs = [ makeWrapper ];
              installPhase =
                let
                  environment-setters = concatStringsSep " " (
                    [
                      "--set SVDIR '${cfg.settings.environment.svdir}'"
                      "--set LOGDIR '${cfg.settings.environment.logdir}'"
                    ]
                    ++ (optionals (cfg.settings.environment.svwait != null) [
                      "--set SVWAIT '${toString cfg.settings.environment.svwait}'"
                    ])
                  );
                in
                ''
                  mkdir -p $out/bin;

                  while read -rd "" _executable; do
                    ln -sfv "$_executable" "$out/bin/";

                    wrapProgram "$out/bin/''${_executable##*/}" ${environment-setters};
                  done < <("${pkgs.lib.getExe pkgs.findutils}" "${cfg.package.outPath}/bin" -maxdepth 1 -type f -executable -print0)
                '';
            };
            type = package;
          };
        };
      };
    };

    services = mkOption {
      description = "";

      example = literalExpression ''
        services.sshd = {
          package = pkgs.openssh;
          name = "sshd";
          run-up = '''
            #!''${pkgs.runtimeShell}
            exec ''${pkgs.openssh}/bin/sshd -f "''${config.environment.etc."ssh/sshd_config".outPatn}" -De 2>&1
          ''';
        };
      '';

      type = attrsOf (submodule mkService);
    };
  };

  config = mkIf cfg.enable {
    environment.packages = [ cfg.settings.packageWrapped ];

    ## This does not seem to work, not without further investigation/fiddling
    # environment.sessionVariables = {
    #   SVDIR = cfg.settings.environment.svdir;
    # };

    ## nix-community/nix-on-droid -> modules/build/activation.nix
    build.activation =
      let
        services = mkIf (cfg.services != { }) (
          mapAttrs
            (
              name: service:
                let
                  package-check = attrByPath [ "execute" "check" ] null service;
                  package-finish = attrByPath [ "execute" "finish" ] null service;
                  package-log-run = attrByPath [ "execute" "log" "run" ] null service;

                  controlMappedToLink =
                    { directory, control-config }:
                    mapAttrs
                      (character: package: ''
                        $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe package}" "${directory}/${character}";
                      '')
                      (filterAttrs (_name: package: package != null) control-config);

                  control-service-links = controlMappedToLink {
                    directory = "${cfg.settings.environment.svdir}/${name}/control";
                    control-config = service.execute.control;
                  };

                  control-log-links = controlMappedToLink {
                    directory = "${cfg.settings.environment.svdir}/${name}/log/control";
                    control-config = control-service-links;
                  };

                  svlogd-config = optionalString (service.svlogd.enable && service.svlogd.config != null) (
                    if (typeOf service.svlogd.config) == "path" then
                      ''
                        $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${service.svlogd.config}" "${cfg.settings.environment.svdir}/${name}/log/config";
                      ''
                    else if (typeOf service.svlogd.config) == "string" then
                      ''
                        $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${
                          (writeTextFile {
                            name = "svlogd-${name}";
                            text = service.svlogd.config;
                          }).outPath
                        }" "${cfg.settings.environment.svdir}/${name}/log/config";
                      ''
                    else
                      throw "`runit.services.${name}.svlogd.config` is neither `string` or `path` type"
                  );
                in
                ''
                  ## Where log files will be written?
                  $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.environment.logdir}/${name}";

                  $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.environment.svdir}/${name}/log";

                  ## pid and lock files expected to live here
                  $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.environment.svdir}/${name}/supervise";

                  ## `./run` executable expected to be here for starting
                  $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe service.execute.run}" "${cfg.settings.environment.svdir}/${name}/run";
                ''
                + optionalString (package-check != null) ''
                  ## `./check` executable expected to be to modify how `sv` checks for service states
                  $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe package-check}" "${cfg.settings.environment.svdir}/${name}/check";
                ''
                + optionalString (package-finish != null) ''
                  ## `./finish` executable expected to be here when `${name}/run` exits
                  $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe package-finish}" "${cfg.settings.environment.svdir}/${name}/finish";
                ''
                + optionalString (package-log-run != null) ''
                  ## `./log/run` executable expected to be here for logging
                  $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe package-log-run}" "${cfg.settings.environment.svdir}/${name}/log/run";
                ''
                + optionalString (service.execute.control != { }) ''
                  $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.environment.svdir}/${name}/control";
                  ${concatStringsSep "\n" (attrValues control-service-links)}
                ''
                + optionalString (service.execute.log.control != { }) ''
                  $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.environment.svdir}/${name}/log/control";
                  ${concatStringsSep "\n" (attrValues control-log-links)}
                ''
                + optionalString service.svlogd.enable ''
                  ${svlogd-config}
                ''
            )
            (filterAttrs (_name: service: service.enable) cfg.services)
        );

        init = mkIf cfg.settings.init.enable {
          setup =
            let
              init-executables = mapAttrs
                (
                  name: executable:
                    if executable != null then
                      ''
                        $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${getExe executable}" "${cfg.settings.init.dir}/${name}";
                      ''
                    else
                      lib.warn ''
                        Missing runit system init executable: ${name}

                        Your system may not be correctly configured, please check the description;
                        ${cfg.settings.init.executables.${name}.description}
                      '' ""
                )
                cfg.settings.init.executables;

            in
            ''
              ## Runit system init
              $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${cfg.settings.init.dir}";
              ${concatStringsSep "\n" (attrValues init-executables)}
            '';
        };
      in
      services // init;
  };
}
