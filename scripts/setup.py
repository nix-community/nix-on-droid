from setuptools import setup, find_packages

setup(
    name='nix-on-droid-deploy-script',
    version='0.0',
    packages=[],
    py_modules=["deploy"],
    entry_points={
        'console_scripts': [
            'deploy=deploy:go',
        ],
    },
)
