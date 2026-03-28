#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# Bake nginx.conf.template — vars must match Dockerfile CMD envsubst list.
set -euo pipefail
out="${1:?output path}"
tpl="${2:?template path}"
export OTEL_COLLECTOR_HOST="${OTEL_COLLECTOR_HOST:-otel-collector}"
export IMAGE_PROVIDER_PORT="${IMAGE_PROVIDER_PORT:-8081}"
export OTEL_COLLECTOR_PORT_GRPC="${OTEL_COLLECTOR_PORT_GRPC:-4317}"
export OTEL_SERVICE_NAME="${OTEL_SERVICE_NAME:-image-provider}"
if ! command -v envsubst >/dev/null 2>&1; then
  echo "bake_nginx.sh: envsubst not found; install gettext-base (e.g. apt-get install gettext-base)." >&2
  exit 1
fi
# Dockerfile: envsubst '$OTEL_COLLECTOR_HOST $IMAGE_PROVIDER_PORT $OTEL_COLLECTOR_PORT_GRPC $OTEL_SERVICE_NAME'
envsubst '$OTEL_COLLECTOR_HOST $IMAGE_PROVIDER_PORT $OTEL_COLLECTOR_PORT_GRPC $OTEL_SERVICE_NAME' < "$tpl" > "$out"
