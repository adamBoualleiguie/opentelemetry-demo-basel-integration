#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
ROOT="${BUILD_WORKSPACE_DIRECTORY:?Run with: bazel run //:sanitycheck}"
cd "$ROOT"
exec python3 internal/tools/sanitycheck.py
