# Computer setup

Scripts to set up a Linux, WSL or Windows machine with my preferred tools. The package lists and personal settings live in YAML files, so one set of lists drives every platform, and a **work** profile can install a smaller, safer set than the **personal** one.

## Quick start

### Linux and WSL

```bash
git clone https://github.com/markbac/scripts-computerSetupInfo.git
cd scripts-computerSetupInfo
cp config/config.example.yml config/config.local.yml    # then edit your name and email
Linux/setup.sh --dry-run                                # see what would change
Linux/setup.sh                                          # do it
```

`Linux/setup.sh` installs Ansible if it is missing, then runs `Linux/ansible/site.yml`. It asks for your sudo password only when sudo needs one, and never stores it.

Supported: Ubuntu 24.04 (the package names were checked against it), and Debian or other Ubuntu releases where the same packages exist. WSL is detected automatically.

### Windows

Open a normal (not elevated) PowerShell window:

```powershell
git clone https://github.com/markbac/scripts-computerSetupInfo.git
cd scripts-computerSetupInfo
Copy-Item config\config.example.yml config\config.local.yml    # then edit your name and email
.\Windows\setup.ps1 -DryRun
.\Windows\setup.ps1
```

It installs Scoop packages as your user, then asks for administrator rights only for the Chocolatey and winget part, because Scoop refuses to install as administrator. `Windows\setup.bat` starts the same script from a command prompt or a double-click.

> **Note:** If PowerShell blocks the script, run it with `powershell -ExecutionPolicy Bypass -File .\Windows\setup.ps1`, or use `Windows\setup.bat`, which does this for you. A managed work machine may forbid this.

## Profiles

Every package list has two tiers.

| Profile | Installs |
| --- | --- |
| `work` (default) | the `base` lists only: tools that are fine on a managed machine |
| `personal` | `base` plus the `personal` lists: games, toys, extra apps |

Choose in `config/config.local.yml` (`profile: personal`) or for a single run:

```bash
Linux/setup.sh --profile personal
```

```powershell
.\Windows\setup.ps1 -Profile personal
```

The full list for each profile is in [docs/packages.md](docs/packages.md).

## Configuration

| File | Purpose |
| --- | --- |
| `config/config.example.yml` | Defaults: profile, git name and email, SSH key and apt upgrade switches. Committed. |
| `config/config.local.yml` | Your copy, git-ignored. Overrides the example key by key. |
| `config/packages.yml` | Every package, in one file: `common` (cargo, npm, pipx, VS Code extensions), `linux` (apt, snap, flatpak, brew, Python libraries, fonts, optional installers) and `windows` (winget, Scoop, Chocolatey) |
| `config/pins.yml` | Pinned versions and SHA-256 checksums for downloaded installers |

Each group in `packages.yml` has a `base` and a `personal` list. To add a package, add it to the right list and run `python3 docs/generate_packages.py` to refresh the table.

### Pinned downloads

Anything fetched outside a package manager (nvm, oh-my-zsh, Homebrew's installer, Nerd Fonts, ctop, browsh, pfetch) comes from a pinned version or commit and is checked against a SHA-256 in `config/pins.yml` before it is used. A mismatch stops that step. Three things are not pinned by checksum because the vendor publishes no fixed file: the rustup download (its checksum is read from the same release), and the Scoop and Chocolatey bootstrap scripts, which are downloaded to a file and then run, never piped into a shell.

## Running part of it

Linux sections are Ansible tags: `apt`, `vscode`, `shell`, `git`, `dotfiles`, `fonts`, `python`, `node`, `rust`, `wsl`, `apps`, `brew`, `extras`.

```bash
Linux/setup.sh --tags apt,dotfiles
Linux/setup.sh --dry-run --tags fonts
```

Windows sections are `-Section User` (Scoop and the cross-platform tools) and `-Section Machine` (Chocolatey and winget, needs administrator rights).

### Dry runs, logs and failures

- `--dry-run` (Linux) and `-DryRun` (Windows) change nothing and report what would be installed.
- Real runs are logged to `~/setup-<date>.log` on both platforms.
- A failing step does not stop the others. The failures are listed at the end and the exit code is non-zero.
- Running it again is safe. Installed packages are skipped, and a second run reports `changed=0`.

## What it does besides packages

- **Dotfiles.** `.bashrc`, `.zshrc`, `.profile` and `.p10k.zsh` from `Linux/config/` are symlinked into your home directory. A regular file already there is kept as `<name>.pre-setup`. Put settings for one machine in `~/.shellrc.local`, which the dotfiles load if it exists.
- **Git.** Sets `user.name` and `user.email` from your config. It can also create an ed25519 SSH key (`generate_ssh_key: true`), which is off by default because the key has no passphrase.
- **WSL.** Turns on systemd in `/etc/wsl.conf` (run `wsl --shutdown` from Windows afterwards). `Windows\setup.ps1` copies `Windows/config/.wslconfig` to your profile if you do not have one. Snap, Flatpak and fonts are skipped inside WSL because they belong on the Windows side.
- **Wave Terminal.** Installed from winget on Windows, and from snap on a desktop Linux (skipped inside WSL).

## Tests

```bash
tests/run.sh
```

Runs the config checks, shellcheck, yamllint, ansible-lint, an Ansible syntax check, an idempotency test of the dotfile and git sections in a throw-away home directory, and a PowerShell dry run when `pwsh` and the `powershell-yaml` module are available. Checks whose tools are missing are skipped with a note. Nothing is installed.

## Layout

```text
config/                 settings, package lists and pins (shared by every platform)
Linux/setup.sh          bootstrap: installs Ansible and runs the playbook
Linux/ansible/          site.yml and one task file per section
Linux/config/           dotfiles that get symlinked into your home directory
Windows/setup.ps1       Windows installer (setup.bat is a launcher)
Windows/config/         .wslconfig
docs/                   generated package table and personal notes
tests/                  run.sh and the config validator
```

More notes, kept for reference, are in [docs/notes.md](docs/notes.md).
