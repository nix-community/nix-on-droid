# Runit for Nix on Android

Once services are configured correctly the following command may be used to start all;

```bash
runsvdir ~/../usr/var/service
```

Within another session check process tree via;

```bash
ps xf
```

Each service `NAME` will create directories/files by default under `${config.build.installationDir}/var/service` with the following structure;

- `./run` Required: used to start a service, defined by `runit.services.NAME.execute.run`
- `./check` Optional: used to customize how service up/down state is checked, defined by `runit.services.NAME.execute.check`
- `./conf` Not implemented
- `./finish` Optional: called by runit when `./run` exits, defined by `runit.services.NAME.execute.finish`
- `./log/config` Optional: used by `svlogd` to modify log behaviors, defined by `runit.services.NAME.svlogd.config` and enabled by `runit.services.NAME.svlogd.enable`
- `./log/run` Optional: useful for defining CLI arguments for `svlogd` defined by `runit.services.NAME.execute.log.run`

## Examples

### OpenSSH (snippet)

```nix
      runit.services.sshd = mkIf (config.runit.enable) {
        package = pkgs.openssh;
        enable = true;
        execute = {
          run = writeScriptBin "service-sshd-run" ''
            #!${pkgs.runtimeShell}

            ${pkgs.openssh}/bin/ssh-keygen -Af ${config.build.installationDir}

            mkdir -p ${builtins.dirOf cfg.settings.PidFile}

            exec ${pkgs.openssh}/bin/sshd -f "${config.environment.etc."ssh/sshd_config".source}" -De 2>&1
          '';
          log.run = writeScriptBin "service-sshd-log" ''
            #!${pkgs.runtimeShell}

            exec "${config.runit.package.outPath}/bin/svlogd" -tt "${config.runit.settings.environment.svdir}/sshd";
          '';
        };
      };
```

### OpenSSH modified from `${nixpkgs}/nixos/modules/services/networking/ssh/sshd.nix`

```nix
{
  config,
  lib,
  nixpkgs,
  pkgs,
  utils,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMapStrings
    concatStringsSep
    elem
    filterAttrs
    flip
    hasPrefix
    isList
    length
    listToAttrs
    mapAttrs
    mkDfault
    mkIf
    nameValuePair
    readFile
    removeAttrs
    ;

  inherit (pkgs)
    writeScriptBin
    ;

  mod = {
    sshd = import "${nixpkgs}/nixos/modules/services/networking/ssh/sshd.nix" {
      inherit
        config
        lib
        pkgs
        ;
    };
  };

  settingsFormat =
    let
      # reports boolean as yes / no
      mkValueString = with lib; v:
            if isInt           v then toString v
            else if isString   v then v
            else if true  ==   v then "yes"
            else if false ==   v then "no"
            else throw "unsupported type ${builtins.typeOf v}: ${(lib.generators.toPretty {}) v}";

      base = pkgs.formats.keyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } " ";
      };
      # OpenSSH is very inconsistent with options that can take multiple values.
      # For some of them, they can simply appear multiple times and are appended, for others the
      # values must be separated by whitespace or even commas.
      # Consult either sshd_config(5) or, as last resort, the OpehSSH source for parsing
      # the options at servconf.c:process_server_config_line_depth() to determine the right "mode"
      # for each. But fortunaly this fact is documented for most of them in the manpage.
      commaSeparated = [ "Ciphers" "KexAlgorithms" "Macs" ];
      spaceSeparated = [ "AuthorizedKeysFile" "AllowGroups" "AllowUsers" "DenyGroups" "DenyUsers" ];
    in {
      inherit (base) type;
      generate = name: value:
        let transformedValue = mapAttrs (key: val:
          if isList val then
            if elem key commaSeparated then concatStringsSep "," val
            else if elem key spaceSeparated then concatStringsSep " " val
            else throw "list value for unknown key ${key}: ${(lib.generators.toPretty {}) val}"
          else
            val
          ) value;
        in
          base.generate name transformedValue;
    };

  configFile = settingsFormat.generate "sshd.conf-settings" (filterAttrs (n: v: v != null) cfg.settings);
  sshconf = pkgs.runCommand "sshd.conf-final" { } ''
    cat ${configFile} - >$out <<EOL
    ${cfg.extraConfig}
    EOL
  '';


  cfg = config.services.openssh;

  prepend_build_installationDir = path: "${cfg.build.installationDir}/${path}";
in
{
  options.services.openssh = mod.sshd.options.services.openssh // {
    generateHostKeys.default = mkDfault false;
    generateHostKeys.description = concatStringsSep "\n\n" [
      mod.sshd.options.services.openssh.generateHostKeys.description
      ''
        Nix on Droid defaults to `false` to disable;

        - `config.systemd.services."sshd@"`
        - `config.systemd.services.sshd`
        - `config.systemd.services.sshd-keygen`
      ''
    ];

    openFirewall.default = mkDfault false;
    openFirewall.description = concatStringsSep "\n\n" [
      mod.sshd.options.services.openssh.openFirewall.description
      ''
        Nix on Droid defaults to `false` to disable;

        - `config.networking.firewall.allowedTCPPorts`
      ''
    ];

    hostKeys.default = lib.map (attrs: attrs // {
      path = prepend_build_installationDir attrs.path;
    }) mod.sshd.options.services.openssh.hostKeys.default;
    hostKeys.description = concatStringsSep "\n\n" [
      mod.sshd.options.services.openssh.hostKeys.description
      ''
        Nix on Droid pre-pends `"''${cfg.build.installationDir}/"` to each `path` in list of attributes
      ''
    ];
  };

  config =
    let
      sshdConfigContentFiltered = (removeAttrs mod.sshd.config.content [
        ## Requires `users.users` which requires `boot.initrd.enable`
        "users"
        "environment"
        "security"

        ## Requires `networking.firewall`
        "networking"

        ## Requires SystemD which assumes Root and boot stuff
        "systemd"

        ## Skipping `system.checks`
        "system"
      ]);
    in
    mkIf cfg.enable (sshdConfigContentFiltered // {
      environment.etc = {
        # "ssh/moduli".source = cfg.moduliFile;
        "ssh/sshd_config".source = sshconf;
      };

      services.openssh.authorizedKeysFiles =
        lib.optional cfg.authorizedKeysInHomedir
          lib.map (path:
            if hasPrefix "/etc/ssh" path then
              prepend_build_installationDir path
            else
              path
          ) sshdConfigContentFiltered.services.openssh.authorizedKeysFiles;

      services.openssh.settings.AuthorizedPrincipalsFile =
        mkIf (sshdConfigContentFiltered.services.openssh ? "AuthorizedPrincipalsFile" && sshdConfigContentFiltered.services.openssh.AuthorizedPrincipalsFile != {})
          (prepend_build_installationDir sshdConfigContentFiltered.services.openssh.AuthorizedPrincipalsFile)
          ;

      ## TODO: Get clever about modifying submodule
      services.openssh.settings.PidFile = "${config.build.installationDir}/run/sshd.pid";
      services.openssh.settings.UsePAM = false;

      ## Define `runit` integration here!
      runit.services.sshd = mkIf (config.runit.enable) {
        package = pkgs.openssh;
        enable = true;
        execute = {
          run = writeScriptBin "service-sshd-run" ''
            #!${pkgs.runtimeShell}

            ${pkgs.openssh}/bin/ssh-keygen -Af ${config.build.installationDir}

            mkdir -p "${builtins.dirOf cfg.settings.PidFile}"

            exec ${pkgs.openssh}/bin/sshd -f "${config.environment.etc."ssh/sshd_config".source}" -De 2>&1
          '';
          log.run = writeScriptBin "service-sshd-log" ''
            #!${pkgs.runtimeShell}

            exec "${config.runit.package.outPath}/bin/svlogd" -tt "${config.runit.settings.environment.svdir}/sshd";
          '';
        };
      };
    });
}
```

## Notes and Warnings

- Replacing system init is **not** tested, however, most of the `options` _should_ be defined for those that wish to test this
- This module is likely incompatible with upstream NixOS, for now, and assistance is welcomed for making this compatible with upstream NixOS packages
- NixOS defines `systemd` options, such as `serviceConfig.ExecStart`, which could be _borrowed_ by this module. But no plans, currently, are planned to automate this
- Currently no `/home/username` options are provided for defining user-level services with `runit`

______

## Attributions

- [Arch Wiki -- Runit](https://wiki.artixlinux.org/Main/Runit)
- [Gentoo Wiki -- runit](https://wiki.gentoo.org/wiki/Runit)
- [GitHub -- `NixOS/nixpkgs` -- Issue 24346 -- Can I replace systemd with OpenRC or runit on NixOS?](https://github.com/NixOS/nixpkgs/issues/24346)
- [GitHub -- `cleverca22/not-os` -- `master:./runit.nix`](https://github.com/cleverca22/not-os/blob/master/runit.nix)
- [GitHub -- `rubyists/runit-services`](https://github.com/rubyists/runit-services/)
- [GitHub -- `termux/termux-packages` -- Issue 17 -- unable to open supervise/ok: file does not exist](https://github.com/termux/termux-services/issues/17)
- [GitHub -- `termux/termux-packages` -- Issue 25479 [Bug]: sv enbable `<service_name>` fails with "file does not exist" despite directory existing](https://github.com/termux/termux-packages/issues/25479)
- [GitHub -- `termux/termux-packages` -- Issue 25861 -- [Bug]: OpenSSH package doesn't check whether sshd and ssh-agent are enabled during preinstall, both get disabled after every upgrade](https://github.com/termux/termux-packages/issues/25861)
- [GitHub -- `termux/termux-packages` -- v0.14](https://github.com/termux/termux-services/blob/0.14)
- [GitHub Pages -- kchard -- runit-quickstart](https://kchard.github.io/runit-quickstart/)
- [Medium -- mrinjamul -- Create and manage services in Termux (Linux-based Android Terminal)](https://mrinjamul.medium.com/create-and-manage-services-in-termux-linux-based-android-terminal-5120c4694199)
- [NixOS Discourse -- Setting an environment variable for a single package?](https://discourse.nixos.org/t/setting-an-environment-variable-for-a-single-package/15075/6)
- [Termux Wiki -- Termux-services](https://wiki.termux.com/wiki/Termux-services)
- [Void Linux Docs -- Services and Daemons -- runit](https://docs.voidlinux.org/config/services/index.html)
- [YouTube -- Joseph Choe -- Running with runit!](https://www.youtube.com/watch?v=8dGHkFCmosU)
- [smarden -- `runit/sv.8`](https://smarden.org/runit/sv.8)
- [smarden -- `runit`](https://smarden.org/runit/)
