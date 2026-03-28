#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# Bazel sh_test: locate src/react-native-app (Bzlmod workspace name varies).
_RN_ROOT=""
if [[ -n "${TEST_SRCDIR:-}" ]]; then
  for _base in "${TEST_SRCDIR}"/*; do
    [[ -d "${_base}/src/react-native-app" ]] || continue
    if [[ -f "${_base}/src/react-native-app/package.json" ]]; then
      _RN_ROOT="${_base}/src/react-native-app"
      break
    fi
  done
fi
if [[ -z "${_RN_ROOT}" ]]; then
  echo "run_rn_js_checks: could not resolve src/react-native-app (TEST_SRCDIR=${TEST_SRCDIR:-})" >&2
  exit 1
fi

cd "${_RN_ROOT}"
export NPM_CONFIG_CACHE="$(mktemp -d)"
trap 'rm -rf "${NPM_CONFIG_CACHE}"' EXIT

if ! command -v node >/dev/null 2>&1; then
  echo "node not found on PATH; install Node.js 20+ (see README)." >&2
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found on PATH." >&2
  exit 1
fi

npm ci --no-audit --no-fund
# Typecheck (strict TS; Expo base config).
npm exec -- tsc --noEmit
# Jest (jest-expo); no in-tree tests yet — still validates preset + resolution.
npm exec -- jest --ci --watchAll=false --passWithNoTests
