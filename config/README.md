# Package config

Package lists split by platform, with a `base` and a `personal` tier.

## Layout

```text
config/
  packages/
    common.yml     # npm, pip (same on every OS)
    linux.yml      # apt, brew, snap (Linux and WSL)
    windows.yml    # winget, scoop
```

- `base` is safe for a work machine.
- `personal` is for home machines only. A personal profile installs `base` plus `personal`.

> **Note:** Nothing reads these files yet. The existing package lists are still in the scripts and playbooks. Migrating them here and wiring the installers to read this config is tracked in #9, #8 and #16.

## Current contents

These files hold the additions from #17 (Wave Terminal, `gh` and extra tooling), all under `base`.
