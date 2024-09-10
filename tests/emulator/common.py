# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE

import pathlib
import sys
import time

SERVER = 'https://nix-on-droid.unboiled.info'
# Just use F-Droid through fdroidctl later when F-Droid has x86_64 builds
APK = f'{SERVER}/com.termux.nix_188035-x86_64.apk'
BOOTSTRAP_URL = 'file:///data/local/tmp/n-o-d'


def screenshot(d, suffix=''):
    screenshots = pathlib.Path('screenshots')
    screenshots.mkdir(exist_ok=True)
    fname_base = screenshots / f'{time.time():.3f}-{suffix}'
    d.ui.screenshot(str(fname_base.with_suffix('.png')))
    fname_base.with_suffix('.xml').write_text(d.ui.dump_hierarchy())
    print(f'screenshotted: {fname_base}.{{png,xml}}')


def wait_for(d, on_screen_text, timeout=90, critical=True):
    start = time.time()
    last_displayed_time = None
    while (elapsed := time.time() - start) < timeout:
        display_time = int(timeout - elapsed)
        if display_time != last_displayed_time:
            print(f'waiting for `{on_screen_text}`: {display_time}s...')
            sys.stdout.flush()
            last_displayed_time = display_time
        if on_screen_text in d.ui.dump_hierarchy():
            print(f'found: {on_screen_text} after {elapsed:.1f}s')
            return
        time.sleep(0.75)
    print(f'NOT FOUND: {on_screen_text} after {timeout}s')
    screenshot(d, suffix='error')
    if critical:
        sys.exit(1)
