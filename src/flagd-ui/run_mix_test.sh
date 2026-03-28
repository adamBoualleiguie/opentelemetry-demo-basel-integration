#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# Bazel sh_test: locate src/flagd-ui under runfiles (Bzlmod workspace name varies).
_MIX_ROOT=""
if [[ -n "${TEST_SRCDIR:-}" ]]; then
  for _base in "${TEST_SRCDIR}"/*; do
    [[ -d "${_base}/src/flagd-ui" ]] || continue
    if [[ -f "${_base}/src/flagd-ui/mix.exs" ]]; then
      _MIX_ROOT="${_base}/src/flagd-ui"
      break
    fi
  done
fi
if [[ -z "${_MIX_ROOT}" ]]; then
  echo "run_mix_test: could not resolve src/flagd-ui (TEST_SRCDIR=${TEST_SRCDIR:-})" >&2
  exit 1
fi

cd "${_MIX_ROOT}"
export MIX_ENV=test
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
_H="$(mktemp -d)"
export HOME="${_H}"
trap 'rm -rf "${_H}"' EXIT

git config --global --add safe.directory '*' 2>/dev/null || true
if ! command -v mix >/dev/null 2>&1; then
  echo "mix not found on PATH; install Elixir/OTP (see README)." >&2
  exit 1
fi

mix local.hex --force
mix local.rebar --force
mix deps.get
mix test --color=false
