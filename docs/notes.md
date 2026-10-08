# Notes

Loose notes that used to live in the main README. They are not part of the automated setup.

## Useful tools that are easy to install by script

- [mdSilo](https://github.com/mdSilo/mdSilo-app/releases)
- [noted](https://github.com/scottashipp/noted), scripted note taking based on markdown
  - See also [My Note Taking Process](https://dev.to/scottshipp/my-note-taking-process-49pa)

## nushell and oh-my-posh

Nushell is installed from Homebrew on the personal profile. For the prompt, see the [oh-my-posh prompt guide](https://ohmyposh.dev/docs/installation/prompt).

The old `let-env PROMPT_COMMAND = ...` line no longer works because `let-env` was removed from recent nushell releases. Set it with `$env.PROMPT_COMMAND` instead, or generate the whole block with `oh-my-posh init nu`. The file `Linux/config/.oh-my-posh.nu` is output from that command. It is not linked into your home directory by the setup because it points at a specific Homebrew version of oh-my-posh and at a theme file in a hardcoded home directory.

## Chromebook

### Set or reset the password

```bash
sudo passwd
```

### VS Code

Download the Arm64 build from the [VS Code download page](https://code.visualstudio.com/Download).

## ChatGPT on the command line

```bash
python3 -m pip install --user git+https://github.com/mmabrouk/chatgpt-wrapper
playwright install firefox
playwright install-deps
chatgpt install
```

Log in to ChatGPT in the browser when asked. After that, run `chatgpt`.

## Installing the Windows package managers by hand

`Windows\setup.ps1` does this for you. These are the manual steps.

### Chocolatey

From an administrator PowerShell. See the [Chocolatey install guide](https://www.liquidweb.com/kb/how-to-install-chocolatey-on-windows/).

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

> **Warning:** This runs a script straight from the internet. Read it first, or download it to a file and inspect it before running it.

### Scoop

From a normal (not administrator) PowerShell.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### Rust

```powershell
scoop install rustup
```
