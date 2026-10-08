#!/usr/bin/env bash
# Runs every check that does not install anything on this machine.
#
#   tests/run.sh
#
# Needs python3 with PyYAML. These tools are optional and their checks are
# skipped with a note when missing: shellcheck, yamllint, ansible-lint,
# ansible-playbook, git, ssh-keygen and pwsh (the PowerShell dry run also
# needs pwsh to have the powershell-yaml module).

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

failures=0
skipped=0
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

section() { printf '\n== %s\n' "$1"; }
pass() { printf '   ok: %s\n' "$1"; }
fail() { printf '   FAIL: %s\n' "$1"; failures=$((failures + 1)); }
skip() { printf '   skipped: %s\n' "$1"; skipped=$((skipped + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

check() { # check <description> <command...>
    local description="$1"
    shift
    if "$@" >"$work/out" 2>&1; then
        pass "$description"
    else
        fail "$description"
        sed 's/^/        /' "$work/out" | head -20
    fi
}

section "Config files"
check "YAML structure, tiers and pins" python3 -I tests/validate_config.py
check "docs/packages.md matches the YAML" python3 -I docs/generate_packages.py --check

section "Shell scripts and dotfiles"
if have shellcheck; then
    check "shellcheck setup.sh and this script" shellcheck -S style Linux/setup.sh tests/run.sh
else
    skip "shellcheck is not installed"
fi
check "bash syntax of setup.sh" bash -n Linux/setup.sh
for dotfile in .bashrc .profile; do
    check "bash syntax of $dotfile" bash -n "Linux/config/$dotfile"
done
# Sourcing must succeed on a machine with none of the optional tools.
clean_home="$work/clean-home"
mkdir -p "$clean_home"
check ".bashrc sources cleanly with no optional tools" \
    env -i HOME="$clean_home" PATH=/usr/bin:/bin bash --norc -c ". '$root/Linux/config/.bashrc'"
check ".profile sources cleanly with no optional tools" \
    env -i HOME="$clean_home" PATH=/usr/bin:/bin bash --norc -c ". '$root/Linux/config/.profile'"
if have zsh; then
    check "zsh syntax of .zshrc and .p10k.zsh" bash -c "zsh -n Linux/config/.zshrc && zsh -n Linux/config/.p10k.zsh"
else
    skip "zsh is not installed"
fi
check "no personal paths in the dotfiles or scripts" bash -c \
    "! grep -rn 'mbacon\|bacon\.me' Linux/setup.sh Linux/ansible Linux/config/.bashrc Linux/config/.zshrc Linux/config/.profile Windows config"
check "setup.sh rejects --profile without a value" bash -c "! Linux/setup.sh --profile 2>/dev/null"

section "YAML and Ansible"
if have yamllint; then
    check "yamllint" yamllint -c .yamllint config Linux/ansible .yamllint
else
    skip "yamllint is not installed"
fi
if have ansible-playbook; then
    check "ansible-playbook --syntax-check" bash -c "cd Linux/ansible && ansible-playbook site.yml --syntax-check < /dev/null"
else
    skip "ansible-playbook is not installed"
fi
if have ansible-lint; then
    check "ansible-lint (production profile)" bash -c "cd Linux/ansible && ansible-lint site.yml"
else
    skip "ansible-lint is not installed"
fi

section "Idempotency (dotfiles and git, in a throw-away home directory)"
if have ansible-playbook && have git && have ssh-keygen; then
    # Work on a copy of config/ so a real config.local.yml is never touched.
    cp -r config "$work/config"
    cat >"$work/config/config.local.yml" <<'EOF'
user:
  git_name: Test User
  git_email: test@example.org
  generate_ssh_key: true
EOF
    test_home="$work/home"
    mkdir -p "$test_home"
    echo "# original" >"$test_home/.bashrc"
    run_play() {
        (cd Linux/ansible &&
            HOME="$test_home" GIT_CONFIG_GLOBAL="$test_home/.gitconfig" ANSIBLE_NOCOLOR=1 \
                ansible-playbook site.yml -e "config_dir=$work/config" --tags dotfiles,git </dev/null)
    }
    if run_play >"$work/run1" 2>&1; then pass "first run succeeds"; else fail "first run"; tail -15 "$work/run1"; fi
    if run_play >"$work/run2" 2>&1 && grep -q 'changed=0 ' "$work/run2"; then
        pass "second run changes nothing"
    else
        fail "second run should report changed=0"
        grep -E 'changed:|PLAY RECAP|localhost ' "$work/run2" | head
    fi
    check "dotfiles are symlinks into the repository" test "$(readlink "$test_home/.bashrc")" = "$root/Linux/config/.bashrc"
    check "the original .bashrc was kept" grep -q '^# original$' "$test_home/.bashrc.pre-setup"
    check "git identity was written" test "$(git config --file "$test_home/.gitconfig" user.email)" = "test@example.org"
    check "ssh key has private permissions" test "$(stat -c %a "$test_home/.ssh/id_ed25519")" = "600"
else
    skip "needs ansible-playbook, git and ssh-keygen"
fi

section "Windows PowerShell script"
if have pwsh; then
    # The single quotes are deliberate: this is PowerShell code, not shell.
    # shellcheck disable=SC2016
    check "setup.ps1 parses" pwsh -NoProfile -Command \
        '$e=$null;$t=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("Windows/setup.ps1",[ref]$t,[ref]$e);if($e.Count){$e|Out-String|Write-Error;exit 1}'
    if pwsh -NoProfile -Command 'if (Get-Module -ListAvailable powershell-yaml) { exit 0 } else { exit 1 }'; then
        for profile in work personal; do
            if pwsh -NoProfile -File Windows/setup.ps1 -DryRun -Profile "$profile" >"$work/ps-$profile" 2>&1 ||
                grep -q 'dry run' "$work/ps-$profile"; then
                expected="$(python3 -I - "$profile" <<'EOF'
import sys, yaml
profile = sys.argv[1]
data = yaml.safe_load(open("config/packages/windows.yml"))["scoop"]
print(len(data["base"]) + (len(data["personal"]) if profile == "personal" else 0))
EOF
)"
                if grep -q "scoop: $expected wanted" "$work/ps-$profile"; then
                    pass "dry run, $profile profile: $expected scoop packages as in the YAML"
                else
                    fail "dry run, $profile profile: expected $expected scoop packages"
                    head -20 "$work/ps-$profile"
                fi
            else
                fail "dry run, $profile profile did not run"
                head -20 "$work/ps-$profile"
            fi
        done
    else
        skip "the powershell-yaml module is not installed for pwsh"
    fi
else
    skip "pwsh is not installed"
fi

printf '\n'
if [ "$failures" -gt 0 ]; then
    printf '%d check(s) FAILED, %d skipped\n' "$failures" "$skipped"
    exit 1
fi
printf 'All checks passed, %d skipped\n' "$skipped"
