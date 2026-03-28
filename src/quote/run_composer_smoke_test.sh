#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# Bazel sh_test: locate src/quote under runfiles (Bzlmod workspace name varies).
_QUOTE_ROOT=""
if [[ -n "${TEST_SRCDIR:-}" ]]; then
  for _base in "${TEST_SRCDIR}"/*; do
    [[ -d "${_base}/src/quote" ]] || continue
    if [[ -f "${_base}/src/quote/composer.json" ]]; then
      _QUOTE_ROOT="${_base}/src/quote"
      break
    fi
  done
fi
if [[ -z "${_QUOTE_ROOT}" ]]; then
  echo "run_composer_smoke_test: could not resolve src/quote (TEST_SRCDIR=${TEST_SRCDIR:-})" >&2
  exit 1
fi

cd "${_QUOTE_ROOT}"
export COMPOSER_NO_INTERACTION=1 COMPOSER_ALLOW_SUPERUSER=1
_H="$(mktemp -d)"
export COMPOSER_HOME="${_H}"
trap 'rm -rf "${_H}"' EXIT

if ! command -v composer >/dev/null 2>&1; then
  echo "composer not found on PATH; install PHP + Composer (see README)." >&2
  exit 1
fi
if ! command -v php >/dev/null 2>&1; then
  echo "php not found on PATH; install PHP (see README)." >&2
  exit 1
fi

composer install \
  --ignore-platform-reqs \
  --no-interaction \
  --no-plugins \
  --no-scripts \
  --no-dev \
  --prefer-dist

php -r 'require "vendor/autoload.php"; echo "autoload_ok\n";'
