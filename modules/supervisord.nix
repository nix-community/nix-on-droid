{ pkgs, lib, config, ... }:
let
  inherit (lib) types;

  cfg = config.supervisord;

  format = pkgs.formats.ini {};

  programType = types.submodule ({ name, config, ... }: {
    options = {
      enable = lib.mkOption {
        description = ''
          Whether to enable this program.
        '';
        type = types.bool;
        default = true;
      };
      command = lib.mkOption {
        description = ''
          The command that will be run as the service's main process.
        '';
        type = types.str;
        default = toString (pkgs.writeShellScript "${name}-script.sh" config.script);
      };
      script = lib.mkOption {
        description = ''
          Shell commands executed as the service's main process.
        '';
        type = types.lines;
        default = "";
      };
      path = lib.mkOption {
        description = ''
          Packages added to the service's PATH environment variable.
        '';
        type = types.listOf (types.either types.package types.str);
        default = [];
      };
      autoRestart = lib.mkOption {
        description = ''
          Whether to automatically restart the process if it exits.
        '';
        type = types.either types.bool (types.enum [ "false" "true" "unexpected" ]);
        default = "unexpected";
      };
      environment = lib.mkOption {
        description = ''
          Environment variables passed to the service's process.
        '';
        type = types.attrsOf types.str;
        default = {
          PATH = lib.makeBinPath config.path;
        };
      };
      extraConfig = lib.mkOption {
        description = ''
          Extra structured configurations to add to the [program:x] section.
        '';
        type = types.attrsOf types.str;
        default = {};
      };
    };
  });

  renderAtom = val:
    if builtins.isBool val then if val then "true" else "false"
    else toString val;

  renderProgram = program: let
    section = {
      inherit (program) command;
      autorestart = program.autoRestart;
      environment = let
        # FIXME: Make more robust
        escape = builtins.replaceStrings [ "%" ] [ "%%" ];
        envs = lib.mapAttrsToList (k: v: "${k}=\"${escape v}\"") program.environment;
      in builtins.concatStringsSep "," envs;
    } // program.extraConfig;
  in lib.mapAttrs (_: v: renderAtom v) section;

  numPrograms = builtins.length (builtins.attrNames cfg.programs);
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
        description = ''
          Whether to enable the supervisord process control system.

          This allows you to define long-running services in Nix-on-Droid.
        '';
        type = types.bool;
        default = numPrograms != 0;
      };
      package = lib.mkOption {
        description = ''
          The supervisord package to use.
        '';
        type = types.package;
        default = pkgs.python3Packages.supervisor;
        defaultText = lib.literalExpression "pkgs.python3Packages.supervisor";
      };
      socketPath = lib.mkOption {
        description = ''
          Path to the UNIX domain socket on which supervisord will listen on.
        '';
        type = types.path;
        default = "/tmp/supervisor.sock";
      };
      pidPath = lib.mkOption {
        description = ''
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
        description = ''
          Definition of supervisord programs.
        '';
        type = types.attrsOf programType;
        default = {};
      };
      configFile = lib.mkOption {
        type = types.package;
        internal = true;
        default = configFile;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."supervisord.conf" = {
      source = cfg.configFile;
    };

    environment.packages = [ supervisorctl ];

    build.activationAfter.reloadSupervisord = ''
      ${cfg.package}/bin/supervisorctl -c /etc/supervisord.conf update
    '';
  };
}
