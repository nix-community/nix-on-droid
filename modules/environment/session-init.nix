# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;

  export = n: v: "export ${n}=\"${toString v}\"";

  exportAll = vars: concatStringsSep "\n" (mapAttrsToList export vars);

  addToNixPath = nixPathEntry: ''
    if [[ ":$NIX_PATH:" != *":${nixPathEntry}:"* ]]; then
      export NIX_PATH="${nixPathEntry}''${NIX_PATH:+:}$NIX_PATH"
    fi
  '';

  sessionInit = pkgs.writeTextFile {
    name = "nix-on-droid-session-init.sh";
    destination = "/etc/profile.d/nix-on-droid-session-init.sh";
    text = ''
      # Only source this once.
      [ -n "$__NOD_SESS_INIT_SOURCED" ] && return
      export __NOD_SESS_INIT_SOURCED=1

      . "${config.user.home}/.nix-profile/etc/profile.d/nix.sh"

      # workaround for nix 2.4, see https://github.com/NixOS/nixpkgs/issues/149791
      ${addToNixPath "${config.user.home}/.nix-defexpr/channels"}
      # Workaround for https://github.com/NixOS/nix/issues/1865
      ${addToNixPath "nixpkgs=${config.user.home}/.nix-defexpr/channels/nixpkgs/"}

      ${optionalString (config.home-manager.config != null) ''
        if [ -e "${config.user.home}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
          . "${config.user.home}/.nix-profile/etc/profile.d/hm-session-vars.sh"
        fi
      ''}

      ${exportAll cfg.sessionVariables}
    '';
  };
in

{

  ###### interface

  options = {

    environment = {
      motd = mkOption {
        default = ''
          Welcome to Nix-on-Droid!
          If nothing works, open an issue at https://github.com/nix-community/nix-on-droid/issues or try the rescue shell.
        '';
        type = types.nullOr types.lines;
        description = ''
          Text to show on every new shell created by Nix-on-Droid.
        '';
      };

      sessionVariables = mkOption {
        default = { };
        type = types.attrs;
        example = { EDITOR = "emacs"; GS_OPTIONS = "-sPAPERSIZE=a4"; };
        description = ''
          Environment variables to always set at login.

          </para><para>

          The values may refer to other environment variables using
          POSIX.2 style variable references. For example, a variable
          <varname>parameter</varname> may be referenced as
          <code>$parameter</code> or <code>''${parameter}</code>. A
          default value <literal>foo</literal> may be given as per
          <code>''${parameter:-foo}</code> and, similarly, an alternate
          value <literal>bar</literal> can be given as per
          <code>''${parameter:+bar}</code>.

          </para><para>

          Note, these variables may be set in any order so no session
          variable may have a runtime dependency on another session
          variable. In particular code like

          <programlisting language="nix">
          environment.sessionVariables = {
            FOO = "Hello";
            BAR = "$FOO World!";
          };
          </programlisting>

          may not work as expected. If you need to reference another
          session variable, then do so inside Nix instead. The above
          example then becomes

          <programlisting language="nix">
          environment.sessionVariables = {
            FOO = "Hello";
            BAR = "''${config.environment.sessionVariables.FOO} World!";
          };
          </programlisting>
        '';
      };
    };

  };


  ###### implementation

  config = {

    build = { inherit sessionInit; };

    environment = {
      packages = [ sessionInit ];

      sessionVariables = {
        HOME = config.user.home;
        USER = config.user.userName;

        # To prevent gc warnings of nix, see https://github.com/NixOS/nix/issues/3237
        GC_NPROCS = 1;
        # Fix locale (perl apps panic without it)
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      };
    };

  };

}
