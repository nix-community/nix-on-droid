_:

{
  system.stateVersion = "23.11";
  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
    okc-gpg.enable = false; # building takes an eternity, tested separately
    # unsupported.enable = false;
  };
}
