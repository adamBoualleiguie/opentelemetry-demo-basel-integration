#!/usr/bin/env python3
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
"""BZ-720: Ensure MODULE.bazel oci.pull names match tools/bazel/policy/oci_base_allowlist.txt."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def _repo_root(script_path: Path) -> Path:
    p = script_path.resolve().parent
    for _ in range(8):
        if (p / "MODULE.bazel").is_file():
            return p
        p = p.parent
    raise SystemExit("Could not locate MODULE.bazel above this script.")


def extract_oci_pull_names(module_text: str) -> list[str]:
    """Return oci.pull `name =` values in file order."""
    return re.findall(
        r'oci\.pull\(\s*\n\s*name\s*=\s*"([^"]+)"',
        module_text,
        flags=re.MULTILINE,
    )


def load_allowlist(path: Path) -> list[str]:
    lines: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if line:
            lines.append(line)
    return lines


def main() -> int:
    script = Path(__file__)
    root = _repo_root(script)
    module_path = root / "MODULE.bazel"
    allow_path = script.resolve().parent / "oci_base_allowlist.txt"

    module_text = module_path.read_text(encoding="utf-8")
    pulled = extract_oci_pull_names(module_text)
    allowed = load_allowlist(allow_path)

    allow_set = set(allowed)
    pull_set = set(pulled)

    errors: list[str] = []
    for name in pulled:
        if name not in allow_set:
            errors.append(f"oci.pull name {name!r} is not in {allow_path}")
    for name in allowed:
        if name not in pull_set:
            errors.append(f"Allowlist entry {name!r} has no matching oci.pull in MODULE.bazel")

    if errors:
        print("check_oci_allowlist.py: FAILED", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        return 1

    print(f"check_oci_allowlist.py: OK ({len(pulled)} oci.pull names)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
