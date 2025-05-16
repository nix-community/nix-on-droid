import bootstrap_channels

from common import screenshot, wait_for


def run(d):
    bootstrap_channels.run(d)

    d('input text "zip"')
    d.ui.press('enter')
    wait_for(d, 'bash: zip: command not found')
    screenshot(d, 'no-zip')

    # Smoke-test nix-shell + change config + apply config
    d('input text "nix-shell -p gnumake -p gnused"')
    d.ui.press('enter')
    wait_for(d, '[nix-shell:~]$')
    d('input text "make"')
    d.ui.press('enter')
    wait_for(d, 'No targets specified and no makefile found.')
    screenshot(d, 'nix-shell-with-make-and-sed')
    # Change config and apply it
    d('input text \'sed -i "s|#zip|zip|g" .config/nixpkgs/nix-on-droid.nix\'')
    d.ui.press('enter')
    d('input text "exit"')
    d.ui.press('enter')
    screenshot(d, 'pre-switch')
    d('input text "nix-on-droid switch"')
    d.ui.press('enter')
    screenshot(d, 'post-switch')

    # Verify zip is there
    d('input text "zip -v | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'This is Zip')
    screenshot(d, 'zip-appears')

    # Re-login and make sure login is still operational

    d('input text "exit"')
    d.ui.press('enter')

    nod = d.app('com.termux.nix')
    nod.launch()
    screenshot(d, 're-login')
    wait_for(d, 'Installing new login-inner...')
    wait_for(d, 'bash-5.2$')
    screenshot(d, 're-login-done')

    # And verify zip is still there
    d('input text "zip -v | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'This is Zip')
    screenshot(d, 'zip-is-still-there')

    def change_shell_and_relogin(shell, descr):
        import base64
        import time
        config = ('{pkgs, ...}: {user.shell = %SHELL%; ' +
                  'system.stateVersion = "24.11";}').replace('%SHELL%', shell)
        config_base64 = base64.b64encode(config.encode()).decode()
        d(f'input text "echo {config_base64} | base64 -d > '
          '~/.config/nixpkgs/nix-on-droid.nix"')
        d.ui.press('enter')
        screenshot(d, f'pre-switch-{descr}')
        d(f'input text "nix-on-droid switch && echo switched  {descr}"')
        d.ui.press('enter')
        time.sleep(1)
        screenshot(d, f'in-switch-{descr}')
        wait_for(d, f'switched {descr}')
        screenshot(d, f'post-switch-{descr}')
        d('input text "exit"')
        d.ui.press('enter')
        screenshot(d, f'pre-re-login-{descr}')
        d.app('com.termux.nix').launch()
        time.sleep(1)
        screenshot(d, f'post-re-login-{descr}')

    # change shell: pkgs.fish -> fish
    change_shell_and_relogin('pkgs.fish', 'bare-fish')
    wait_for(d, 'Welcome to fish, the friendly interactive shell')
    screenshot(d, 're-login-done-bare-fish')

    # change shell: "${pkgs.fish}", which is a directory -> fallback
    change_shell_and_relogin('"${pkgs.fish}"', 'fish-directory')
    wait_for(d, 'Cannot execute shell ')
    wait_for(d, 'it is a directory.')
    wait_for(d,
             "You should point 'user.shell' to the exact binary.")
    wait_for(d, 'Falling back to bash.')
    wait_for(d, 'bash-5.2$')
    screenshot(d, 're-login-done-shell-dir-fallback')

    # change shell: "${pkgs.fish}/bin/fish" -> fish
    change_shell_and_relogin('"${pkgs.fish}/bin/fish"', 'fish-bin-fish')
    wait_for(d, 'Welcome to fish, the friendly interactive shell')
    screenshot(d, 're-login-done-fish-bin-fish')
