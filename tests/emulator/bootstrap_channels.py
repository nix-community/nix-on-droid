# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE

import time

from common import APK, BOOTSTRAP_URL, screenshot, wait_for


def run(d):
    nod = d.app('com.termux.nix', url=APK)
    nod.permissions.allow_notifications()
    nod.launch()
    time.sleep(0.5)

    wait_for(d, 'Bootstrap zipball location')
    time.sleep(0.5)
    screenshot(d, 'initial')
    d.ui(className='android.widget.EditText').set_text(BOOTSTRAP_URL)
    time.sleep(0.5)
    screenshot(d, 'entered-url')
    for _ in range(2):
        if 'text="OK"' not in d.ui.dump_hierarchy():
            d.ui.press('back')
            time.sleep(0.5)
        else:
            break
    time.sleep(0.5)
    screenshot(d, 'entered-url-back')
    time.sleep(0.5)
    d.ui(text='OK').click()
    screenshot(d, 'ok-clicked')

    wait_for(d, 'Welcome to Nix-on-Droid!')
    screenshot(d, 'bootstrap-begins')
    wait_for(d, 'Do you want to set it up with flakes? (y/N)')
    d.ui.press('enter')
    wait_for(d, 'Setting up Nix-on-Droid with channels...')

    wait_for(d, 'Installing and updating nix-channels...')
    wait_for(d, 'unpacking channels...')
    wait_for(d, 'Installing first Nix-on-Droid generation...', timeout=600)
    wait_for(d, 'Copying default Nix-on-Droid config...', timeout=180)
    wait_for(d, 'Congratulations!')
    wait_for(d, 'See config file for further information.')
    wait_for(d, 'bash-5.2$')
    screenshot(d, 'bootstrap-ends')

    d('input text "echo smoke-test | base64"')
    d.ui.press('enter')
    wait_for(d, 'c21va2UtdGVzdAo=')

    screenshot(d, 'success-bootstrap-channels')

    return nod
