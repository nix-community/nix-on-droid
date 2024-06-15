import bootstrap_channels
import on_device_tests


def run(d):
    bootstrap_channels.run(d)
    on_device_tests.run(d)
