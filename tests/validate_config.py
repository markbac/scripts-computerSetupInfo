#!/usr/bin/env python3
"""Check the YAML config for structural mistakes.

Run from anywhere: python3 tests/validate_config.py
Exits non-zero and lists every problem found.
"""

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "config"
TIERS = {"base", "personal"}
SHA256 = re.compile(r"^[0-9a-f]{64}$")

# Which pin each optional installer in linux.yml needs.
INSTALLER_PINS = {
    "rustup": "rustup",
    "nvm": "nvm",
    "oh_my_zsh": "oh_my_zsh",
    "homebrew": "homebrew_install",
    "ctop": "ctop",
    "browsh": "browsh",
    "pfetch": "pfetch",
    "gitupdate": "gitupdate",
    "swagger_editor": "swagger_editor",
}
# Installers that need a checksum, and where it lives.
SHA_AT_TOP = {"nvm", "oh_my_zsh", "homebrew_install", "pfetch"}
SHA_PER_ARCH = {"ctop", "browsh"}

errors = []


def err(message):
    errors.append(message)


def load(path):
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as exc:
        err(f"{path.relative_to(ROOT)}: cannot load: {exc}")
        return None


def check_packages(path, data):
    rel = path.relative_to(ROOT)
    if not isinstance(data, dict) or not data:
        err(f"{rel}: expected a mapping of package groups")
        return
    for group, tiers in data.items():
        if not isinstance(tiers, dict) or set(tiers) != TIERS:
            err(f"{rel}: '{group}' must have exactly the keys base and personal")
            continue
        seen = {}
        for tier in sorted(TIERS):
            items = tiers[tier]
            if not isinstance(items, list):
                err(f"{rel}: '{group}.{tier}' must be a list")
                continue
            for item in items:
                if not isinstance(item, str) or not item.strip():
                    err(f"{rel}: '{group}.{tier}' has an empty or non-string entry: {item!r}")
                    continue
                key = item.lower()
                if key in seen:
                    where = "twice in " + tier if seen[key] == tier else f"in both {seen[key]} and {tier}"
                    err(f"{rel}: '{item}' listed {where} under '{group}'")
                seen[key] = tier


def check_settings(data):
    rel = "config/config.example.yml"
    if not isinstance(data, dict):
        err(f"{rel}: expected a mapping")
        return
    if data.get("profile") not in {"work", "personal"}:
        err(f"{rel}: profile must be 'work' or 'personal'")
    user = data.get("user")
    if not isinstance(user, dict):
        err(f"{rel}: missing 'user' mapping")
        return
    for key in ("git_name", "git_email", "generate_ssh_key"):
        if key not in user:
            err(f"{rel}: user.{key} is missing")


def check_pins(pins, linux):
    if not isinstance(pins, dict):
        err("config/pins.yml: expected a mapping")
        return
    for name in SHA_AT_TOP:
        value = (pins.get(name) or {}).get("sha256", "")
        if not SHA256.match(str(value)):
            err(f"config/pins.yml: {name}.sha256 must be 64 lowercase hex characters")
    for name in SHA_PER_ARCH:
        for arch, value in ((pins.get(name) or {}).get("sha256") or {}).items():
            if not SHA256.match(str(value)):
                err(f"config/pins.yml: {name}.sha256.{arch} must be 64 lowercase hex characters")
    font_sums = (pins.get("nerd_fonts") or {}).get("sha256") or {}
    for value in font_sums.values():
        if not SHA256.match(str(value)):
            err("config/pins.yml: nerd_fonts.sha256 values must be 64 lowercase hex characters")
    if not linux:
        return
    wanted = linux.get("fonts", {})
    for font in wanted.get("base", []) + wanted.get("personal", []):
        if font not in font_sums:
            err(f"config/pins.yml: font '{font}' is listed in linux.yml but has no checksum")
    installers = linux.get("installers", {})
    for tier in TIERS:
        for name in installers.get(tier, []):
            pin = INSTALLER_PINS.get(name)
            if pin is None:
                if name != "vscode" and name != "chrome":
                    err(f"linux.yml: installer '{name}' is not known to the validator")
            elif pin not in pins:
                err(f"config/pins.yml: installer '{name}' has no '{pin}' pin")


def main():
    settings = load(CONFIG / "config.example.yml")
    check_settings(settings)

    packages = {}
    for path in sorted((CONFIG / "packages").glob("*.yml")):
        data = load(path)
        check_packages(path, data)
        packages[path.stem] = data

    check_pins(load(CONFIG / "pins.yml"), packages.get("linux"))

    if errors:
        print(f"{len(errors)} problem(s) found:")
        for message in errors:
            print(f"  - {message}")
        return 1
    print(f"OK: checked config.example.yml, pins.yml and {len(packages)} package files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
