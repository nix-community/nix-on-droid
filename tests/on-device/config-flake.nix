{
  description = "nix-on-droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-on-droid, ... }: {
    nix-on-droid = (nix-on-droid.lib.aarch64-linux.nix-on-droid {
      config = /data/data/com.termux.nix/files/home/.config/nixpkgs/nix-on-droid.nix;
    }).activationPackage;
  };
}
