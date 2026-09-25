# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

    system.stateVersion = mkOption {
      type = types.str;
      description = ''
        It is occasionally necessary for Nix-on-Droid to change
        configuration defaults in a way that is incompatible with
        stateful data. This could, for example, include switching the
        default data format or location of a file.

        </para><para>

        The <emphasis>state version</emphasis> indicates which default
        settings are in effect and will therefore help avoid breaking
        program configurations. Switching to a higher state version
        typically requires performing some manual steps, such as data
        conversion or moving files.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = match "[0-9]{2}\\.[0-9]{2}" config.system.stateVersion != null;
        message = ''
          ${config.system.stateVersion} is an invalid value for 'system.stateVersion'; it must be in the format "YY.MM",
          which corresponds to a prior release of NixOS.

          If you want to switch releases or switch to unstable, you should change your channel and/or flake input URLs only.
          *DO NOT* touch the 'system.stateVersion' option, as it will not help you upgrade.
          Leave it exactly on the previous value, which is likely the value you had for it when you installed your system.
        '';
      }
    ];
  };
}
