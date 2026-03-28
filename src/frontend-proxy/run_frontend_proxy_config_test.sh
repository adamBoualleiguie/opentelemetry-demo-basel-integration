#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

_ROOT=""
if [[ -n "${TEST_SRCDIR:-}" ]]; then
  for _base in "${TEST_SRCDIR}"/*; do
    [[ -d "${_base}/src/frontend-proxy" ]] || continue
    if [[ -f "${_base}/src/frontend-proxy/envoy.tmpl.yaml" ]]; then
      _ROOT="${_base}/src/frontend-proxy"
      break
    fi
  done
fi
if [[ -z "${_ROOT}" ]]; then
  echo "run_frontend_proxy_config_test: could not resolve src/frontend-proxy" >&2
  exit 1
fi

_TMP="$(mktemp)"
trap 'rm -f "${_TMP}"' EXIT
bash "${_ROOT}/bake_envoy.sh" "${_TMP}" "${_ROOT}/envoy.tmpl.yaml"
grep -q 'static_resources:' "${_TMP}"
grep -q 'cluster: frontend' "${_TMP}"
grep -q 'opentelemetry_collector_grpc' "${_TMP}"
