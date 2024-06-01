import bootstrap_channels

from common import screenshot, wait_for


def run(d):
    nod = bootstrap_channels.run(d)

    d('input text "am"')
    d.ui.press('enter')
    wait_for(d, 'bash: am: command not found')
    screenshot(d, 'no-am')

    # Apply a config that enables am
    cfg = ('/data/local/tmp/n-o-d/unpacked/tests/on-device/'
           'config-android-integration.nix')
    d(f'input text \'cp {cfg} .config/nixpkgs/nix-on-droid.nix\'')
    d.ui.press('enter')
    screenshot(d, 'pre-switch')
    d('input text "nix-on-droid switch"')
    d.ui.press('enter')
    screenshot(d, 'post-switch')

    # Verify am is there
    d('input text "am | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'termux-am is a wrapper script')
    screenshot(d, 'am-appears')

    # Smoke-test that am doesn't work yet
    d('input text "am start -a android.settings.SETTINGS 2>&1 | head -n5"')
    d.ui.press('enter')
    screenshot(d, 'am-invoked for the first time')
    wait_for(d, 'Nix requires "Display over other apps" permission')
    wait_for(d, 'https://dontkillmyapp.com')
    screenshot(d, 'am-wants-permission')

    # Grant nix app 'Draw over other apps' permission
    nod.permissions += 'android.permission.SYSTEM_ALERT_WINDOW'

    # Smoke-test that am works
    d('input text "am start -a android.settings.SETTINGS"')
    d.ui.press('enter')
    screenshot(d, 'settings-opening')
    wait_for(d, 'Search settings')
    wait_for(d, 'Network')
    d.ui.press('back')
    screenshot(d, 'back-from-settings')

    # Verify we're back
    d('input text "am | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'termux-am is a wrapper script')
