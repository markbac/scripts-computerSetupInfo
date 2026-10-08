# Configuration

Settings, package lists and pinned downloads, shared by the Linux and Windows installers. The main [Readme](../Readme.md) explains how they are used.

```text
config/
  config.example.yml    # defaults, committed
  config.local.yml      # your copy, git-ignored
  pins.yml              # versions and SHA-256 checksums for downloads
  packages/
    common.yml          # cargo, npm, pipx, vscode_extensions
    linux.yml           # apt, snap, flatpak, brew, pip_libs, fonts, installers
    windows.yml         # winget, scoop, choco
```

Every group in a package file has exactly two keys, and both must be present even when empty:

- `base` is safe for a work machine.
- `personal` is added on top when the profile is `personal`.

`python3 tests/validate_config.py` checks this, rejects duplicates, and checks that every optional installer and font has a pin. After changing a list, run `python3 docs/generate_packages.py` to refresh `docs/packages.md`.
