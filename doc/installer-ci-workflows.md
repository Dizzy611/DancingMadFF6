# Installer CI Workflows

This document describes manual GitHub Actions workflows used to build installer artifacts.

## Individual Workflows

### Linux AppImage

Workflow: `.github/workflows/installer-appimage.yml`

Inputs:

1. `run_recipe_tests` (bool)
2. `publish_to_release` (bool)
3. `release_tag` (string)

Default mode creates an artifact only. If `publish_to_release=true`, it uploads the AppImage file directly to the specified release tag.

### Windows (Qt5)

Workflow: `.github/workflows/installer-windows.yml`

Inputs:

1. `publish_to_release` (bool)
2. `release_tag` (string)

Outputs:

1. `DancingMadInstaller.exe` (7z self-extracting executable, auto-runs installer)
2. `DancingMadInstaller-windows-extras.7z`

### macOS (Qt6)

Workflow: `.github/workflows/installer-macos.yml`

Inputs:

1. `publish_to_release` (bool)
2. `release_tag` (string)

Outputs:

1. Intel DMG
2. Arm64 DMG
3. Universal DMG (from merge job)

## Combined One-Click Release Workflow

Workflow: `.github/workflows/installer-release-all.yml`

Purpose:

1. Build Linux, Windows, and macOS (including universal DMG) from one workflow run.
2. Publish all expected release assets in one release upload step.

Inputs:

1. `release_tag` (required)
2. `run_linux_recipe_tests` (optional)

Release assets uploaded by this combined workflow:

1. `*.AppImage`
2. `DancingMadInstaller.exe`
3. `DancingMadInstaller-windows-extras.7z`
4. `DancingMadInstaller-macos-universal.dmg`

## Notes

1. Individual workflows now support both direct manual runs and reusable invocation via `workflow_call`.
2. Combined workflow calls the individual workflows in artifact mode (`publish_to_release=false`) and performs a single final release upload.
3. This avoids duplicate uploads and keeps release publishing centralized.
