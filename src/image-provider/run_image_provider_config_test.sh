#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

_ROOT=""
if [[ -n "${TEST_SRCDIR:-}" ]]; then
  for _base in "${TEST_SRCDIR}"/*; do
    [[ -d "${_base}/src/image-provider" ]] || continue
    if [[ -f "${_base}/src/image-provider/nginx.conf.template" ]]; then
      _ROOT="${_base}/src/image-provider"
      break
    fi
  done
fi
if [[ -z "${_ROOT}" ]]; then
  echo "run_image_provider_config_test: could not resolve src/image-provider" >&2
  exit 1
fi

_TMP="$(mktemp)"
trap 'rm -f "${_TMP}"' EXIT
bash "${_ROOT}/bake_nginx.sh" "${_TMP}" "${_ROOT}/nginx.conf.template"
grep -q 'otel_exporter' "${_TMP}"
grep -q 'listen 8081' "${_TMP}"
grep -q 'root /static' "${_TMP}"
