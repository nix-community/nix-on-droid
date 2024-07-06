import base64
import os
import time

import bootstrap_channels

from common import screenshot, wait_for


def run(d):
    # Set up a GPG key in OpenKeychain
    os.system('fdroidcl update')
    okc = 'org.sufficientlysecure.keychain'
    openkeychain = d.fdroid[okc]
    openkeychain.permissions.allow_notifications()
    openkeychain.launch()
    wait_for(d, 'CREATE MY KEY')
    d.ui(resourceId=f'{okc}:id/create_key_create_key_button').click()
    d.ui(resourceId=f'{okc}:id/create_key_name').set_text('Test Key')
    d.ui(resourceId=f'{okc}:id/create_key_next_button').click()
    time.sleep(.5)
    d.ui(resourceId=f'{okc}:id/create_key_email').set_text('nod@example.org')
    d.ui(resourceId=f'{okc}:id/create_key_next_button').click()
    time.sleep(.5)
    d.ui(resourceId=f'{okc}:id/create_key_next_button').click()
    screenshot(d, 'key-created')

    # Select this key in OkcAgent
    okc_agent = d.fdroid['org.ddosolitary.okcagent']
    okc_agent.permissions.allow_notifications()
    okc_agent.launch()
    time.sleep(1)
    wait_for(d, 'Automatic error reporting')
    d.ui(text='NO').click()
    wait_for(d, 'SELECT GPG KEY')
    d.ui(text='SELECT GPG KEY').click()
    d.ui(text='Test Key <nod@example.org>').click()
    screenshot(d, 'gpg-key-selected')

    # SSH is currently untested (`Error: Could not create description: null`)
    # wait_for(d, 'ADD SSH KEY')
    # d.ui(text='ADD SSH KEY').click()
    # wait_for(d, 'Select authentication key')
    # d.ui(text='Use key: nod@example.org').click()
    # d.ui(text='SELECT').click()
    # screenshot(d, 'ssh-key-selected')

    # Bootstrap
    nod = bootstrap_channels.run(d)
    nod.permissions += 'android.permission.SYSTEM_ALERT_WINDOW'

    # Apply a config that enables okc-agents (but not am)
    cfg_file = '.config/nixpkgs/nix-on-droid.nix'
    config = ('_: { system.stateVersion = "23.11"; '
              'android-integration.okc-gpg.enable = true; }')
    config_base64 = base64.b64encode(config.encode()).decode()
    d(f'input text "echo {config_base64} | base64 -d > {cfg_file}"')
    d.ui.press('enter')
    d('input text "nix-on-droid switch && echo okc-agents  installed"')
    screenshot(d, 'pre-switch')
    d.ui.press('enter')
    wait_for(d, 'okc-agents installed', timeout=1200)
    screenshot(d, 'post-switch')

    # Verify am is not in path
    d('input text "am"')
    d.ui.press('enter')
    wait_for(d, 'bash: am: command not found')
    screenshot(d, 'no-am')

    # Run okc-gpg and see how would it complain
    d('input text "okc-gpg"')
    d.ui.press('enter')
    wait_for(d, 'No supported action is found')
    screenshot(d, 'executed-okc-gpg-no-args')

    # Test that nix-on-droid can use that GPG key through okc-gpg: encryption
    d('input text "echo secret  data > test"')
    d.ui.press('enter')
    screenshot(d, 'pre-encryption')
    d('input text "RUST_BACKTRACE=1 okc-gpg -er nod@example.org test > test.gpg"')
    d.ui.press('enter')
    screenshot(d, 'encryption')
    d('input text "rm test"')
    d.ui.press('enter')
    screenshot(d, 'pre-decryption')
    d('input text "okc-gpg -d test.gpg"')
    d.ui.press('enter')
    screenshot(d, 'decryption')
    wait_for(d, 'secret data')
    wait_for(d, 'Verification result: RESULT_NO_SIGNATURE')
    wait_for(d, 'Decryption result: RESULT_ENCRYPTED')
    screenshot(d, 'decryption-success')

    # Test that nix-on-droid can use that GPG key through okc-gpg: signing
    d('input text "echo signed data > test"')
    d.ui.press('enter')
    d('input text "okc-gpg -s test -o test.sig"')
    d.ui.press('enter')
    d('input text "okc-gpg -v test.sig"')
    d.ui.press('enter')
    screenshot(d, 'verification-attempt')
    wait_for(d, 'secret data')
    wait_for(d, 'Signature from: Test Key <nod@example.org>')
    wait_for(d, 'Created on: ')
    wait_for(d, 'Verification result: RESULT_VALID_KEY_CONFIRMED')
    screenshot(d, 'verification-success')
