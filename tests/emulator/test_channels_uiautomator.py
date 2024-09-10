# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE

import bootstrap_channels
import on_device_tests


def run(d):
    bootstrap_channels.run(d)
    on_device_tests.run(d)
