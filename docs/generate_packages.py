#!/usr/bin/env python3
"""Write docs/packages.md and docs/packages.yml from the YAML package lists.

    python3 docs/generate_packages.py          # rewrite both files
    python3 docs/generate_packages.py --check  # exit 1 if either is out of date

docs/packages.yml is every package in one file, for reading or export. The
installers do not read it: edit config/packages/*.yml instead.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "docs" / "packages.md"
OUTPUT_YAML = ROOT / "docs" / "packages.yml"

SECTIONS = [
    ("common", "Both platforms"),
    ("linux", "Linux and WSL"),
    ("windows", "Windows"),
]


def cell(items):
    return ", ".join(f"`{item}`" for item in items) if items else "none"


def render():
    lines = [
        "# What gets installed",
        "",
        "Generated from `config/packages/*.yml` by `docs/generate_packages.py`. Do not edit by hand.",
        "",
        "The **work** profile installs the base column. The **personal** profile installs both columns.",
    ]
    for stem, title in SECTIONS:
        data = yaml.safe_load((ROOT / "config" / "packages" / f"{stem}.yml").read_text(encoding="utf-8"))
        lines += ["", f"## {title}", "", "| Group | Base | Personal |", "| --- | --- | --- |"]
        for group, tiers in data.items():
            lines.append(f"| `{group}` | {cell(tiers['base'])} | {cell(tiers['personal'])} |")
    return "\n".join(lines) + "\n"


def render_yaml():
    combined = {
        stem: yaml.safe_load((ROOT / "config" / "packages" / f"{stem}.yml").read_text(encoding="utf-8"))
        for stem, _ in SECTIONS
    }
    header = (
        "# Every package in one file, generated from config/packages/*.yml by\n"
        "# docs/generate_packages.py. Do not edit by hand, and the installers do not read it.\n"
        "# Edit config/packages/*.yml instead.\n"
    )
    return header + yaml.safe_dump(combined, sort_keys=False, default_flow_style=False, indent=2)


def main():
    outputs = [(OUTPUT, render()), (OUTPUT_YAML, render_yaml())]
    if "--check" in sys.argv[1:]:
        stale = [o for o, text in outputs if not o.exists() or o.read_text(encoding="utf-8") != text]
        for o in stale:
            print(f"{o.relative_to(ROOT)} is out of date. Run: python3 docs/generate_packages.py")
        if stale:
            return 1
        print("docs/packages.md and docs/packages.yml are up to date")
        return 0
    for o, text in outputs:
        o.write_text(text, encoding="utf-8")
        print(f"wrote {o.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
