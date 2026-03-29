#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
#
# BZ-611 / M4: Faster local / optional PR path — protos, smoke, libraries, unit tests.
# Skips heavy oci_image builds (minutes saved). Use ci_full.sh for complete parity.
#
# Usage:
#   ./tools/bazel/ci/ci_fast.sh
#
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ROOT="$(bazel_ci_repo_root)"
cd "${ROOT}"
BAZEL="$(bazel_ci_bazel)"

run() {
  echo "+ $*"
  "$@"
}

run python3 "${ROOT}/tools/bazel/policy/check_oci_allowlist.py"

run "${BAZEL}" build \
  //:smoke \
  //pb:demo_proto \
  //pb:go_grpc_protos \
  //pb:demo_py_grpc \
  //pb:demo_java_grpc \
  //src/ad:ad \
  //src/fraud-detection:fraud_detection \
  //src/accounting:accounting_publish \
  //src/cart:cart_publish \
  //src/checkout/... \
  //src/product-catalog/... \
  //src/payment/... \
  //src/recommendation:recommendation \
  //src/product-reviews:product_reviews \
  //src/llm:llm \
  //src/load-generator:load_generator \
  //src/shipping:shipping \
  //src/currency:currency \
  //src/email:email \
  //src/flagd-ui:flagd_ui_publish \
  //src/quote:quote_publish \
  //src/frontend-proxy:envoy_compose_defaults_yaml \
  //src/image-provider:nginx_compose_defaults_conf \
  --config=ci

run "${BAZEL}" test //... --config=ci --config=unit --build_tests_only

echo "ci_fast.sh: OK"
