#!/usr/bin/env python3
"""Static checker for literal Godot res:// references in a repository.

Run from the repository root:
    python tools/audit_res_refs.py

Checks literal res:// paths in .gd, .tscn, .tres, .godot, .cfg, .import,
and .md files. This is a static existence check only: it does not validate
Godot syntax, UID resolution, dynamically constructed paths, imported assets,
or runtime behavior.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path.cwd()
SCANNED_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".import", ".md"}
SKIP_DIRS = {".git", ".godot", ".venv", "__pycache__"}
REFERENCE = re.compile(r"""res://([^"'\s)\],;<>]+)""")
TRAILING_PUNCTUATION = ".,:!?}"


def repository_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in relative.parts):
            continue
        if path.suffix.lower() in SCANNED_SUFFIXES:
            yield path


def main() -> int:
    files = list(repository_files())
    missing: list[tuple[str, int, str]] = []
    checked_refs = 0
    unreadable: list[tuple[str, str]] = []

    for source in files:
        try:
            text = source.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError) as exc:
            unreadable.append((str(source), str(exc)))
            continue

        for line_number, line in enumerate(text.splitlines(), 1):
            for match in REFERENCE.finditer(line):
                target = match.group(1).rstrip(TRAILING_PUNCTUATION)
                if not target:
                    continue
                checked_refs += 1
                resolved = ROOT / target
                if not resolved.exists():
                    missing.append((str(source), line_number, target))

    print(f"Repository root: {ROOT}")
    print(f"Files scanned: {len(files)}")
    print(f"Literal res:// references checked: {checked_refs}")
    print(f"Missing targets: {len(missing)}")
    print(f"Unreadable files: {len(unreadable)}")

    if missing:
        print("\nMISSING REFERENCES")
        for source, line, target in missing:
            print(f"{source}:{line}: res://{target}")

    if unreadable:
        print("\nUNREADABLE FILES")
        for source, error in unreadable:
            print(f"{source}: {error}")

    print("\nLimitations: This does not replace Godot import/parser validation or")
    print("runtime testing. Dynamic path construction and UID resolution need")
    print("separate checks. Review every reported match in context.")
    return 1 if missing or unreadable else 0


if __name__ == "__main__":
    sys.exit(main())
