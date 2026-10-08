#!/usr/bin/env bash
# Set up a Debian, Ubuntu or WSL machine.
#
# Installs Ansible if it is missing, then runs Linux/ansible/site.yml. It asks
# for your sudo password only when sudo needs one, and never stores it.
#
# Usage:
#   Linux/setup.sh                       # work profile (or whatever config.local.yml says)
#   Linux/setup.sh --profile personal    # base + personal packages
#   Linux/setup.sh --dry-run             # show what would change, change nothing
#   Linux/setup.sh --tags apt,dotfiles   # only some sections
#   Any other option is passed to ansible-playbook.
#
# A log of each run is written to ~/setup-<date>.log (set SETUP_LOG to change it).

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
playbook_args=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            playbook_args+=(--check --diff)
            ;;
        --profile)
            [ "$#" -ge 2 ] || { echo "--profile needs a value: work or personal" >&2; exit 2; }
            playbook_args+=(-e "profile=$2")
            shift
            ;;
        -h | --help)
            sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            playbook_args+=("$1")
            ;;
    esac
    shift
done

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script supports Debian, Ubuntu and WSL (apt-get was not found)." >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    sudo_cmd=()
else
    command -v sudo >/dev/null 2>&1 || { echo "sudo is required when not running as root." >&2; exit 1; }
    sudo_cmd=(sudo)
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "Installing Ansible from the distribution packages..."
    "${sudo_cmd[@]}" apt-get update
    "${sudo_cmd[@]}" apt-get install -y ansible
fi

# Older Ansible packages may not bundle the collections the playbook uses.
if ! ansible-galaxy collection list 2>/dev/null | grep -q '^community.general'; then
    ansible-galaxy collection install -r "$here/ansible/requirements.yml"
fi

# Only ask for a password when sudo actually needs one.
if [ "${#sudo_cmd[@]}" -gt 0 ] && ! sudo -n true 2>/dev/null; then
    playbook_args+=(--ask-become-pass)
fi

export ANSIBLE_LOG_PATH="${SETUP_LOG:-$HOME/setup-$(date +%Y%m%d-%H%M%S).log}"
echo "Logging to $ANSIBLE_LOG_PATH"

cd "$here/ansible"
ansible-playbook site.yml "${playbook_args[@]}"
