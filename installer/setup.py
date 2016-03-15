from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need
# fine tuning.
buildOptions = dict(packages = [], excludes = [])

import sys
base = 'Win32GUI' if sys.platform=='win32' else None

executables = [
    Executable('Installer.py', base=base)
]

setup(name='Dancing Mad Installer',
      version = '16.03.15',
      description = 'Installer for Dancing Mad FF6 mod, Pre-Alpha.',
      options = dict(build_exe = buildOptions),
      executables = executables)
