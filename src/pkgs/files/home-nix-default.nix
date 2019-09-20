{ writeText }:

writeText "home.nix.default" ''
  { pkgs, ... }:

  {
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Install and configure software declaratively
    #programs.git = {
    #  enable = true;
    #  userName = "Jane Doe";
    #  userEmail = "jane.doe@example.org";
    #};

    # Simply install just the packages
    home.packages = with pkgs; [
      # Stuff that you really really want to have
      nix cacert coreutils  # think twice before removing these

      # User-facing stuff that you really really want to have
      bashInteractive   # think twice before removing thes
      vim  # or some other editor, e.g. nano or neovim

      # Some common stuff that people expect to have
      #diffutils
      #findutils
      #utillinux
      #tzdata
      #hostname
      #man
      #gnugrep
      #gnupg
      #gnused
      #gnutar
      #bzip2
      #gzip
      #xz
      #zip
      #unzip
    ];
  }
''
