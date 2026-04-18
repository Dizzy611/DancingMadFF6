# Installer AppImage Build Notes

This directory now supports two paths:

1. Manual GitHub Action build (recommended)
2. Local build on Fedora Linux

The GitHub Action is defined in `.github/workflows/installer-appimage.yml` and is manually triggered from the Actions tab.

## Why this was changed

The older AppImage was built with a very old Debian base and could fail to launch on newer distros due to missing runtime libraries (notably `libnsl.so.2`).

The current recipe:

1. Uses Ubuntu 22.04 (jammy) package sources in `AppImageBuilder.yml`
2. Explicitly bundles `libnsl2` and related runtime libraries
3. Targets Qt5 packaging while still building from the current CMake project

## Manual GitHub Action (Qt5)

1. Open GitHub Actions.
2. Select `Build Installer AppImage (Qt5)`.
3. Click `Run workflow`.
4. Leave `run_recipe_tests` disabled unless you specifically want containerized recipe tests.
5. Download the resulting artifact named like `DancingMadInstaller-qt5-<sha>.AppImage`.

Optional release upload:

1. Set `publish_to_release` to `true`.
2. Set `release_tag` to the tag you want to publish to.
3. If `publish_to_release` is `false` (default), the run only creates an artifact and does not touch releases.

Notes:

1. The workflow compiles installer code with Qt5 (`-DQT_DEFAULT_MAJOR_VERSION=5`).
2. It stages the built binary into `installer/appimage/AppDir/usr/bin/`.
3. It runs `appimage-builder` and uploads the AppImage as an artifact.
4. When `publish_to_release` is enabled, it also uploads the built AppImage to the specified release tag.

## Bundled Offline Extras

The AppImage now bundles the same core helper files that were previously distributed in `linuxextras.zip`:

1. `ff3msu.ips` (sourced from `patch/ff3msu.ips`)
2. `kefka-16x16.png`
3. `kefka.ico`
4. `kefkalaugh.wav`
5. `mirrors.dat`
6. `songs.xml`

Installer runtime fallback for these files now uses the executable directory (`QCoreApplication::applicationDirPath()`), so AppImage users do not need to place extras beside the AppImage file.

## Local Fedora build (optional)

If you want to test locally on Fedora 42, install dependencies with `dnf`:

```bash
sudo dnf install -y \
	gcc-c++ make cmake ninja-build pkgconf-pkg-config \
	patchelf desktop-file-utils appstream squashfs-tools zsync \
	qt5-qtbase-devel qt5-qttools-devel qt5-qtmultimedia-devel \
	python3-pip
python3 -m pip install --user appimage-builder
```

Build and package:

```bash
cmake -S installer -B build-installer -G Ninja -DQT_DEFAULT_MAJOR_VERSION=5 -DCMAKE_BUILD_TYPE=Release
cmake --build build-installer --parallel
mkdir -p installer/appimage/AppDir/usr/bin
cmake --install build-installer --prefix "$PWD/installer/appimage/AppDir/usr"
cd installer/appimage
~/.local/bin/appimage-builder --recipe AppImageBuilder.yml --skip-test
```

If you want to run recipe tests locally, install Docker or Podman first, then omit `--skip-test`.
