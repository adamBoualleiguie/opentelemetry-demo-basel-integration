#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# BZ-024: aggregate BZ-020–023 (same checks as individual //:* targets).
set -euo pipefail
ROOT="${BUILD_WORKSPACE_DIRECTORY:?Run with: bazel run //:lint}"
cd "$ROOT"
make markdownlint
make yamllint
make misspell
make checklicense
exec python3 internal/tools/sanitycheck.py
