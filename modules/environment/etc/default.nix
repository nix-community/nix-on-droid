# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, ... }:

with lib;

let
  etc' = filter (f: f.enable) (attrValues config.environment.etc);

  etc = pkgs.stdenvNoCC.mkDerivation {
    name = "etc";

    builder = ./make-etc.sh;

    preferLocalBuild = true;
    allowSubstitutes = false;

    sources = map (x: x.source) etc';
    targets = map (x: x.target) etc';
  };

 fileType = types.submodule (
    { name, config, ... }:
    {
      options = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether this /etc file should be generated.  This
            option allows specific /etc files to be disabled.
          '';
        };

        target = mkOption {
          type = types.str;
          description = ''
            Name of symlink (relative to <filename>/etc</filename>).
            Defaults to the attribute name.
          '';
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = "Text of the file.";
        };

        source = mkOption {
          type = types.path;
          description = "Path of the source file.";
        };

      };

      config = {
        target = mkDefault name;
        source = mkIf (config.text != null) (
          let name' = "etc-" + baseNameOf name;
          in mkDefault (pkgs.writeText name' config.text));
      };

    }
  );
in

{

  ###### interface

  options = {

    environment = {
      etc = mkOption {
        type = types.loaOf fileType;
        default = {};
        example = literalExample ''
          {
            example-configuration-file = {
              source = "/nix/store/.../etc/dir/file.conf.example";
            };
            "default/useradd".text = "GROUP=100 ...";
          }
        '';
        description = ''
          Set of files that have to be linked in <filename>/etc</filename>.
        '';
      };

      etcBackupExtension = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ".bak";
        description = ''
          Backup file extension.
          </para><para>
          If a file in <filename>/etc</filename> already exists and is not managed
          by nix-on-droid, the activation fails because we do not overwrite unknown
          files. When an extension is provided through this option, the original
          file will be moved in respect of the backup extension and the activation
          executes successfully.
        '';
      };
    };

  };


  ###### implementation

  config = {

    build = {
      inherit etc;

      activation.setUpEtc = ''
        $DRY_RUN_CMD bash ${./setup-etc.sh} /etc ${etc}/etc ${toString config.environment.etcBackupExtension}
      '';
    };

  };

}
