#!/usr/bin/env python3
"""Write docs/packages.md from config/packages.yml.

    python3 docs/generate_packages.py          # rewrite docs/packages.md
    python3 docs/generate_packages.py --check  # exit 1 if it is out of date
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "docs" / "packages.md"

SECTIONS = [
    ("common", "Both platforms"),
    ("linux", "Linux and WSL"),
    ("windows", "Windows"),
]


def cell(items):
    return ", ".join(f"`{item}`" for item in items) if items else "none"


def render():
    packages = yaml.safe_load((ROOT / "config" / "packages.yml").read_text(encoding="utf-8"))
    lines = [
        "# What gets installed",
        "",
        "Generated from `config/packages.yml` by `docs/generate_packages.py`. Do not edit by hand.",
        "",
        "The **work** profile installs the base column. The **personal** profile installs both columns.",
    ]
    for stem, title in SECTIONS:
        lines += ["", f"## {title}", "", "| Group | Base | Personal |", "| --- | --- | --- |"]
        for group, tiers in packages[stem].items():
            lines.append(f"| `{group}` | {cell(tiers['base'])} | {cell(tiers['personal'])} |")
    return "\n".join(lines) + "\n"


def main():
    text = render()
    if "--check" in sys.argv[1:]:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != text:
            print("docs/packages.md is out of date. Run: python3 docs/generate_packages.py")
            return 1
        print("docs/packages.md is up to date")
        return 0
    OUTPUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
