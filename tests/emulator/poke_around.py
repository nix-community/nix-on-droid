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
