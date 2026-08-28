# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE

from common import screenshot, wait_for


def run(d):
    wait_for(d, 'bash-5.2$')

    d('input text "nix-on-droid on-device-test"')
    d.ui.press('enter')
    wait_for(d, 'These semi-automated tests are destructive', timeout=180)
    wait_for(d, 'Proceeding will wreck your installation.')
    wait_for(d, 'Do you still wish to proceed?')
    d('input text "I do"')
    d.ui.press('enter')
    screenshot(d, 'tests-started')

    d.ui.open_notification()
    d.ui(text='Nix').right(resourceId='android:id/expand_button').click()
    screenshot(d, 'notification_expanded')
    d.ui(description='Acquire wakelock').click()
    screenshot(d, 'wakelock_acquired')
    d.ui(description='Release wakelock').wait()
    screenshot(d, 'gotta-go-back')
    d.ui.press('back')
    screenshot(d, 'went-back')

    if 'text="Allow"' in d.ui.dump_hierarchy():
        d.ui(text='Allow').click()
    elif 'text="ALLOW"' in d.ui.dump_hierarchy():
        d.ui(text='ALLOW').click()
    screenshot(d, 'tests-running')

    wait_for(d, 'tests, 0 failures in', timeout=1200)
    screenshot(d, 'tests-finished')
