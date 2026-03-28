#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# Bake envoy.tmpl.yaml using the same defaults as docker-compose + .env (service DNS names on the demo network).
set -euo pipefail
out="${1:?output path}"
tpl="${2:?template path}"
export ENVOY_ADDR="${ENVOY_ADDR:-0.0.0.0}"
export ENVOY_PORT="${ENVOY_PORT:-8080}"
export ENVOY_ADMIN_PORT="${ENVOY_ADMIN_PORT:-10000}"
export OTEL_SERVICE_NAME="${OTEL_SERVICE_NAME:-frontend-proxy}"
export OTEL_COLLECTOR_HOST="${OTEL_COLLECTOR_HOST:-otel-collector}"
export OTEL_COLLECTOR_PORT_GRPC="${OTEL_COLLECTOR_PORT_GRPC:-4317}"
export OTEL_COLLECTOR_PORT_HTTP="${OTEL_COLLECTOR_PORT_HTTP:-4318}"
export FRONTEND_HOST="${FRONTEND_HOST:-frontend}"
export FRONTEND_PORT="${FRONTEND_PORT:-8080}"
export IMAGE_PROVIDER_HOST="${IMAGE_PROVIDER_HOST:-image-provider}"
export IMAGE_PROVIDER_PORT="${IMAGE_PROVIDER_PORT:-8081}"
export FLAGD_HOST="${FLAGD_HOST:-flagd}"
export FLAGD_PORT="${FLAGD_PORT:-8013}"
export FLAGD_UI_HOST="${FLAGD_UI_HOST:-flagd-ui}"
export FLAGD_UI_PORT="${FLAGD_UI_PORT:-4000}"
export LOCUST_WEB_HOST="${LOCUST_WEB_HOST:-load-generator}"
export LOCUST_WEB_PORT="${LOCUST_WEB_PORT:-8089}"
export GRAFANA_HOST="${GRAFANA_HOST:-grafana}"
export GRAFANA_PORT="${GRAFANA_PORT:-3000}"
export JAEGER_HOST="${JAEGER_HOST:-jaeger}"
export JAEGER_UI_PORT="${JAEGER_UI_PORT:-16686}"
if ! command -v envsubst >/dev/null 2>&1; then
  echo "bake_envoy.sh: envsubst not found; install gettext-base (e.g. apt-get install gettext-base)." >&2
  exit 1
fi
envsubst < "$tpl" > "$out"
