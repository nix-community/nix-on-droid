_:

{
  system.stateVersion = "23.11";
  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-setup-storage.enable = true;
    xdg-open.enable = true;
    # unsupported.enable = false;
  };
}
