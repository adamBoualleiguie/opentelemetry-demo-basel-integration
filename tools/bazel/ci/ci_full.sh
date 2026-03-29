#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
#
# BZ-611 / M4: Full Bazel CI graph (parity with legacy checks.yml bazel_smoke).
# Run from anywhere: builds protos, all migrated binaries, OCI images, unit tests, //:lint.
#
# Usage:
#   ./tools/bazel/ci/ci_full.sh
#   ./tools/bazel/ci/ci_full.sh -- --config=ci   # extra args appended to every command (not supported — use env BAZEL_EXTRA_OPTS)
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

# Single invocation keeps startup cost lower than dozens of separate bazel calls.
run "${BAZEL}" build \
  //:smoke \
  //pb:demo_proto \
  //pb:go_grpc_protos \
  //pb:demo_py_grpc \
  //pb:demo_java_grpc \
  //src/ad:ad \
  //src/ad:ad_oci_image \
  //src/fraud-detection:fraud_detection \
  //src/fraud-detection:fraud_detection_oci_image \
  //src/accounting:accounting_publish \
  //src/accounting:accounting_image \
  //src/cart:cart_publish \
  //src/cart:cart_image \
  //src/checkout/... \
  //src/product-catalog/... \
  //src/payment/... \
  //src/frontend:frontend_image \
  //src/recommendation:recommendation \
  //src/product-reviews:product_reviews \
  //src/llm:llm \
  //src/load-generator:load_generator \
  //src/recommendation:recommendation_image \
  //src/product-reviews:product_reviews_image \
  //src/llm:llm_image \
  //src/load-generator:load_generator_image \
  //src/shipping:shipping \
  //src/shipping:shipping_image \
  //src/currency:currency \
  //src/currency:currency_image \
  //src/email:email \
  //src/email:email_image \
  //src/flagd-ui:flagd_ui_publish \
  //src/flagd-ui:flagd_ui_image \
  //src/quote:quote_publish \
  //src/quote:quote_image \
  //src/frontend-proxy:frontend_proxy_image \
  //src/image-provider:image_provider_image \
  --config=ci

run "${BAZEL}" test \
  //src/checkout/... \
  //src/product-catalog/... \
  //src/shipping/... \
  //src/currency:currency_proto_smoke_test \
  //src/email:email_gems_smoke_test \
  //src/flagd-ui:flagd_ui_mix_test \
  //src/quote:quote_composer_smoke_test \
  //src/react-native-app:rn_js_checks \
  //src/frontend-proxy:frontend_proxy_config_test \
  //src/image-provider:image_provider_config_test \
  //src/cart:cart_dotnet_test \
  //src/frontend:lint \
  --config=ci

run "${BAZEL}" run //:lint --config=ci

echo "ci_full.sh: OK"
