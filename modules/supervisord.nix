# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, lib, config, ... }:
let
  inherit (lib) types;

  cfg = config.supervisord;

  format = pkgs.formats.ini {};

  programType = types.submodule ({ name, config, ... }: {
    options = {
      enable = lib.mkOption {
        description = lib.mdDoc ''
          Whether to enable this program.
        '';
        type = types.bool;
        default = true;
      };
      command = lib.mkOption {
        description = lib.mdDoc ''
          The command that will be run as the service's main process.
        '';
        type = types.str;
      };
      script = lib.mkOption {
        description = lib.mdDoc ''
          Shell commands executed as the service's main process.
        '';
        type = types.lines;
        default = "";
      };
      path = lib.mkOption {
        description = lib.mdDoc ''
          Packages added to the service's PATH environment variable.
        '';
        type = types.listOf (types.either types.package types.str);
        default = [];
      };
      autostart = lib.mkOption {
        description = lib.mdDoc ''
          Whether to automatically start the process.

          If false, the process has to be manually started using
          `supervisorctl`.
        '';
        type = types.bool;
        default = true;
      };
      autoRestart = lib.mkOption {
        description = lib.mdDoc ''
          Whether to automatically restart the process if it exits.

          If `unexpected`, the process will be restarted if it exits
          with an exit code not listed in the programs's `exitcodes`
          configuration.
        '';
        type = types.either types.bool (types.enum [ "false" "true" "unexpected" ]);
        default = "unexpected";
      };
      environment = lib.mkOption {
        description = lib.mdDoc ''
          Environment variables passed to the service's process.
        '';
        type = types.attrsOf types.str;
        default = {};
      };
      extraConfig = lib.mkOption {
        description = lib.mdDoc ''
          Extra structured configurations to add to the [program:x] section.
        '';
        type = types.attrsOf types.str;
        default = {};
      };
    };
    config = {
      command = lib.mkIf (config.script != "")
        (toString (pkgs.writeShellScript "${name}-script.sh" config.script));

      environment.PATH = lib.mkDefault (lib.makeBinPath config.path);
    };
  });

  renderAtom = val:
    if builtins.isBool val then if val then "true" else "false"
    else toString val;

  renderProgram = program: let
    section = {
      inherit (program) command autostart;
      autorestart = program.autoRestart;
      environment = let
        # FIXME: Make more robust
        escape = builtins.replaceStrings [ "%" ] [ "%%" ];
        envs = lib.mapAttrsToList (k: v: "${k}=\"${escape v}\"") program.environment;
      in builtins.concatStringsSep "," envs;
    } // program.extraConfig;
  in lib.mapAttrs (_: v: renderAtom v) section;

  numPrograms = builtins.length (builtins.attrNames enabledPrograms);
  enabledPrograms = lib.filterAttrs (_: program: program.enable) cfg.programs;

  structuredConfig = {
    supervisord = {
      logfile = cfg.logPath;
      pidfile = cfg.pidPath;
    };
    supervisorctl = {
      serverurl = "unix://${cfg.socketPath}";
    };
    unix_http_server = {
      file = cfg.socketPath;
    };
    "rpcinterface:supervisor" = {
      "supervisor.rpcinterface_factory" = "supervisor.rpcinterface:make_main_rpcinterface";
    };
  } // (lib.mapAttrs' (k: v: {
    name = "program:${k}";
    value = renderProgram v;
  }) enabledPrograms);

  configFile = format.generate "supervisord.conf" structuredConfig;

  # Only expose the "supervisorctl" executable
  supervisorctl = pkgs.runCommand "supervisorctl" {} ''
    mkdir -p $out/bin
    ln -s ${cfg.package}/bin/supervisorctl $out/bin/supervisorctl
  '';
in {
  options = {
    supervisord = {
      enable = lib.mkOption {
        description = lib.mdDoc ''
          Whether to enable the supervisord process control system.

          This allows you to define long-running services in Nix-on-Droid.
        '';
        type = types.bool;
        default = numPrograms != 0;
      };
      package = lib.mkOption {
        description = lib.mdDoc ''
          The supervisord package to use.
        '';
        type = types.package;
        default = pkgs.python3Packages.supervisor;
        defaultText = lib.literalExpression "pkgs.python3Packages.supervisor";
      };
      socketPath = lib.mkOption {
        description = lib.mdDoc ''
          Path to the UNIX domain socket on which supervisord will listen on.
        '';
        type = types.path;
        default = "/tmp/supervisor.sock";
      };
      pidPath = lib.mkOption {
        description = lib.mdDoc ''
          Path to the file in which supervisord saves its PID.
        '';
        type = types.path;
        default = "/tmp/supervisor.pid";
      };
      logPath = lib.mkOption {
        description = ''
          Path to the log file.
        '';
        type = types.path;
        default = "/tmp/supervisor.log";
      };
      programs = lib.mkOption {
        description = lib.mdDoc ''
          Definition of supervisord programs.

          Upstream documentations are available at <http://supervisord.org/configuration.html#program-x-section-settings>.
        '';
        type = types.attrsOf programType;
        default = {};
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."supervisord.conf" = {
      source = configFile;
    };

    environment.packages = [ supervisorctl ];

    build.activationAfter.reloadSupervisord = ''
      if [ ! -e "${config.supervisord.socketPath}" ]; then
        echo "Starting supervisord..."
        $DRY_RUN_CMD ${cfg.package}/bin/supervisord -c /etc/supervisord.conf
      else
        echo "Reloading supervisord..."
        $DRY_RUN_CMD ${cfg.package}/bin/supervisorctl -c /etc/supervisord.conf update
      fi
    '';
  };
}
