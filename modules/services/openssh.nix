# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Parts from nixpkgs/nixos/modules/services/networking/ssh/sshd.nix
# MIT Licensed. Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors

{ pkgs, lib, config, ... }:
let
  inherit (lib) types;

  cfg = config.services.openssh;

  uncheckedConf = ''
    ${lib.concatMapStrings (port: ''
      Port ${toString port}
    '') cfg.ports}
    PasswordAuthentication no
    ${lib.flip lib.concatMapStrings cfg.hostKeys (k: ''
      HostKey ${k.path}
    '')}
    ${lib.optionalString cfg.allowSFTP ''
      Subsystem sftp ${cfg.package}/libexec/sftp-server
    ''}
    SetEnv PATH=${config.user.home}/.nix-profile/bin:/usr/bin:/bin
    ${cfg.extraConfig}
  '';

  sshdConf = pkgs.runCommand "sshd.conf-validated" {
    nativeBuildInputs = [ cfg.package ];
  } ''
    cat >$out <<EOL
    ${uncheckedConf}
    EOL

    ssh-keygen -q -f mock-hostkey -N ""
    sshd -t -f $out -h mock-hostkey
  '';
in {
  options = {
    services.openssh = {
      enable = lib.mkOption {
        description = ''
          Whether to enable the OpenSSH secure shell daemon, which
          allows secure remote logins.
        '';
        type = types.bool;
        default = false;
      };
      autostart = lib.mkOption {
        description = ''
          Whether to automatically start the OpenSSH daemon.

          If false, the server has to be manually started using
          `supervisorctl`.
        '';
        type = types.bool;
        default = true;
      };
      package = lib.mkOption {
        description = ''
          The package to use for OpenSSH.
        '';
        type = types.package;
        default = pkgs.openssh;
        defaultText = lib.literalExpression "pkgs.openssh";
      };
      ports = lib.mkOption {
        description = ''
          Specifies on which ports the SSH daemon listens.
        '';
        type = types.listOf types.port;
        default = [ 8022 ];
      };
      allowSFTP = lib.mkOption {
        description = ''
          Whether to enable the SFTP subsystem in the SSH daemon.  This
          enables the use of commands such as {command}`sftp` and
          {command}`sshfs`.
        '';
        type = types.bool;
        default = true;
      };
      hostKeys = lib.mkOption {
        description = ''
          Nix-on-Droid can automatically generate SSH host keys.  This option
          specifies the path, type and size of each key.  See
          {manpage}`ssh-keygen(1)` for supported types
          and sizes.
        '';
        type = types.listOf types.attrs;
        default =
          [ { type = "rsa"; bits = 4096; path = "/etc/ssh/ssh_host_rsa_key"; }
            { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
          ];
        example =
          [ { type = "rsa"; bits = 4096; path = "/etc/ssh/ssh_host_rsa_key"; rounds = 100; openSSHFormat = true; }
            { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; rounds = 100; comment = "key comment"; }
          ];
      };
      extraConfig = lib.mkOption {
        description = "Verbatim contents of {file}`sshd_config`.";
        type = types.lines;
        default = "";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.etc = {
      "ssh/sshd_config".source = sshdConf;
      "ssh/moduli".source = "${cfg.package}/etc/ssh/moduli";
    };

    supervisord.programs.sshd = {
      inherit (cfg) autostart;
      path = [ cfg.package pkgs.coreutils ];
      autoRestart = true;
      script = ''
        # don't write to stdout
        exec >&2

        ${lib.flip lib.concatMapStrings cfg.hostKeys (k: ''
          if ! [ -s "${k.path}" ]; then
              if ! [ -h "${k.path}" ]; then
                  rm -f "${k.path}"
              fi
              mkdir -m 0755 -p "$(dirname '${k.path}')"
              ssh-keygen \
                -t "${k.type}" \
                ${if k ? bits then "-b ${toString k.bits}" else ""} \
                ${if k ? rounds then "-a ${toString k.rounds}" else ""} \
                ${if k ? comment then "-C '${k.comment}'" else ""} \
                ${if k ? openSSHFormat && k.openSSHFormat then "-o" else ""} \
                -f "${k.path}" \
                -N ""
          fi
        '')}

        exec ${cfg.package}/bin/sshd -D -f /etc/ssh/sshd_config
      '';
    };
  };
}
