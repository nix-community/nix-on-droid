import base64
import time

import bootstrap_channels

from common import screenshot, wait_for


def run(d):
    OPENERS = ['termux-open', 'termux-open-url', 'xdg-open']
    TOOLS = ['am', 'termux-setup-storage', 'termux-reload-settings',
             'termux-wake-lock', 'termux-wake-unlock'] + OPENERS

    nod = bootstrap_channels.run(d)

    # Verify that android-integration tools aren't installed by default
    for toolname in TOOLS:
        d(f'input text "{toolname}"')
        d.ui.press('enter')
        wait_for(d, f'bash: {toolname}: command not found')
        screenshot(d, f'no-{toolname}')

    # Apply a config that enables android-integration tools
    cfg = ('/data/local/tmp/n-o-d/unpacked/tests/on-device/'
           'config-android-integration.nix')
    d(f'input text \'cp {cfg} .config/nixpkgs/nix-on-droid.nix\'')
    d.ui.press('enter')
    screenshot(d, 'pre-switch')
    d('input text "nix-on-droid switch && echo integration  tools  installed"')
    d.ui.press('enter')
    wait_for(d, 'integration tools installed')
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

    # ... there might be a notification now, get rid of it
    time.sleep(3)
    screenshot(d, 'am-wants-permission-3-seconds-later')
    if 'text="TermuxAm Socket Server Error"' in d.ui.dump_hierarchy():
        d.ui.open_notification()
        time.sleep(1)
        screenshot(d, 'notification-opened')
        d.ui(text='TermuxAm Socket Server Error').swipe('right')
        screenshot(d, 'error-notification-swiped-right')
        d.ui.press('back')
        screenshot(d, 'back')

    # Grant nix app 'Draw over other apps' permission
    nod.permissions += 'android.permission.SYSTEM_ALERT_WINDOW'

    # Smoke-test that am works
    d('input text "am start -a android.settings.SETTINGS"')
    d.ui.press('enter')
    screenshot(d, 'settings-opening')
    wait_for(d, 'Search settings')
    wait_for(d, 'Network')
    screenshot(d, 'settings-awaited')
    d.ui.press('back')
    screenshot(d, 'back-from-settings')

    # Verify we're back
    d('input text "am | head -n2"')
    d.ui.press('enter')
    wait_for(d, 'termux-am is a wrapper script')

    # Verify termux-setup-storage is there
    d('input text "termux-setup-storage"')
    d.ui.press('enter')
    screenshot(d, 'termux-setup-storage-invoked')
    wait_for(d, 'Allow Nix to access')
    screenshot(d, 'permission-requested')
    if 'text="Allow"' in d.ui.dump_hierarchy():
        d.ui(text='Allow').click()
    elif 'text="ALLOW"' in d.ui.dump_hierarchy():
        d.ui(text='ALLOW').click()
    screenshot(d, 'permission-granted')

    d('input text "ls -l storage"')
    d.ui.press('enter')
    screenshot(d, 'storage-listed')
    wait_for(d, 'pictures -&gt; /storage/emulated/0/Pictures')
    wait_for(d, 'shared -&gt; /storage/emulated/0')
    screenshot(d, 'storage-listed-ok')

    # Invoke termux-setup-storage again
    d('input text "termux-setup-storage"')
    d.ui.press('enter')
    screenshot(d, 'termux-setup-storage-invoked-again')
    wait_for(d, 'already exists')
    wait_for(d, 'Do you want to continue?')
    d.ui.press('enter')
    wait_for(d, 'Aborting configuration and leaving')

    # Verify that *-open* commands work
    for opener in OPENERS:
        d(f'input text "{opener} https://nix-on-droid.unboiled.info/README.txt"')
        d.ui.press('enter')
        screenshot(d, f'{opener}-opened')
        wait_for(d, 'This is Nix-on-Droid.')
        screenshot(d, f'{opener}-waited')
        d.ui.press('back')
        screenshot(d, f'{opener}-back')
        wait_for(d, f'{opener} https://nix-on-droid.unboiled.info/README.txt')

    # test termux-wake-lock/termux-wake-unlock
    d.ui.open_notification()
    screenshot(d, 'notification-opened')
    d.ui(text='Nix').right(resourceId='android:id/expand_button').click()
    screenshot(d, 'notification-expanded')
    wait_for(d, 'Acquire wakelock')
    screenshot(d, 'wakelock-initially-not-acquired')
    d.ui.press('back')

    d('input text "termux-wake-lock"')
    d.ui.press('enter')
    time.sleep(3)
    screenshot(d, 'wake-lock-command')
    if 'Let app always run in background?' in d.ui.dump_hierarchy():
        screenshot(d, 'wake-lock-permission-asked')
        if 'text="Allow"' in d.ui.dump_hierarchy():
            d.ui(text='Allow').click()
        elif 'text="ALLOW"' in d.ui.dump_hierarchy():
            d.ui(text='ALLOW').click()
        screenshot(d, 'wake-lock-permission-granted')
    d.ui.open_notification()
    time.sleep(.5)
    screenshot(d, 'notification-opened')
    wait_for(d, '(wake lock held)')
    if 'Release wakelock' not in d.ui.dump_hierarchy():
        d.ui(text='Nix').right(resourceId='android:id/expand_button').click()
        screenshot(d, 'notification-expanded')
    wait_for(d, 'Release wakelock')
    screenshot(d, 'notification-with-wakelock')
    d.ui.press('back')
    screenshot(d, 'back')
    wait_for(d, 'termux-wake-lock')
    screenshot(d, 'really-back')

    d('input text "termux-wake-unlock"')
    d.ui.press('enter')
    screenshot(d, 'wake-unlock-command')
    d.ui.open_notification()
    time.sleep(.5)
    screenshot(d, 'notification-opened')
    if 'Acquire wakelock' not in d.ui.dump_hierarchy():
        d.ui(text='Nix').right(resourceId='android:id/expand_button').click()
        screenshot(d, 'notification-expanded')
    wait_for(d, 'Acquire wakelock')
    screenshot(d, 'notification-without-wakelock')
    d.ui.press('back')
    screenshot(d, 'back')
    wait_for(d, 'termux-wake-unlock')
    screenshot(d, 'really-back')

    # Test termux-reload-settings
    assert 'text="PGUP"' in d.ui.dump_hierarchy()
    assert 'text="F12"' not in d.ui.dump_hierarchy()

    d('input text "mkdir ~/.termux"')
    d.ui.press('enter')
    cmd = 'echo "extra-keys=[[\'F12\']]" > ~/.termux/termux.properties'
    cmd_base64 = base64.b64encode(cmd.encode()).decode()
    d(f'input text "echo {cmd_base64} | base64 -d | bash -s"')
    d.ui.press('enter')
    screenshot(d, 'pre-reload')
    d('input text "termux-reload-settings"')
    d.ui.press('enter')
    time.sleep(1)
    screenshot(d, 'post-reload')
    assert 'text="PGUP"' not in d.ui.dump_hierarchy()
    assert 'text="F12"' in d.ui.dump_hierarchy()

    d('input text "rm -r ~/.termux"')
    d.ui.press('enter')
    screenshot(d, 'pre-reload-back')
    d('input text "termux-reload-settings"')
    d.ui.press('enter')
    time.sleep(1)
    screenshot(d, 'post-reload-back')
    assert 'text="PGUP"' in d.ui.dump_hierarchy()
    assert 'text="F12"' not in d.ui.dump_hierarchy()
