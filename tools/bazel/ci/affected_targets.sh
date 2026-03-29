#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
#
# BZ-612 / M4: Suggest Bazel test targets affected by git changes (heuristic).
#
# Usage:
#   ./tools/bazel/ci/affected_targets.sh [<base_ref>] [<head_ref>]
# Defaults: base_ref=origin/main (or main), head_ref=HEAD
#
# Prints newline-separated //target patterns (one per line), deduplicated.
#
# Limitations:
# - Path → target mapping is conservative; does not compute fine-grained deps.
# - Full CI still runs ci_full.sh until this is trusted for gating.

set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ROOT="$(bazel_ci_repo_root)"
cd "${ROOT}"

BASE="${1:-origin/main}"
HEAD="${2:-HEAD}"

if ! git rev-parse --verify "${BASE}" >/dev/null 2>&1; then
  if git rev-parse --verify main >/dev/null 2>&1; then
    BASE="main"
  else
    echo "affected_targets.sh: could not resolve base ref (try: git fetch origin)" >&2
    exit 1
  fi
fi

map_path_to_targets() {
  case "$1" in
    src/checkout/*|internal/checkout/*) printf '%s\n' "//src/checkout/..." ;;
    src/product-catalog/*) printf '%s\n' "//src/product-catalog/..." ;;
    src/payment/*) printf '%s\n' "//src/payment/..." ;;
    src/frontend/*) printf '%s\n' "//src/frontend/..." ;;
    src/recommendation/*) printf '%s\n' "//src/recommendation/..." ;;
    src/product-reviews/*) printf '%s\n' "//src/product-reviews/..." ;;
    src/llm/*) printf '%s\n' "//src/llm/..." ;;
    src/load-generator/*) printf '%s\n' "//src/load-generator/..." ;;
    src/shipping/*) printf '%s\n' "//src/shipping/..." ;;
    src/currency/*) printf '%s\n' "//src/currency/..." ;;
    src/email/*) printf '%s\n' "//src/email/..." ;;
    src/flagd-ui/*) printf '%s\n' "//src/flagd-ui/..." ;;
    src/quote/*) printf '%s\n' "//src/quote/..." ;;
    src/accounting/*) printf '%s\n' "//src/accounting/..." ;;
    src/cart/*) printf '%s\n' "//src/cart/..." ;;
    src/ad/*) printf '%s\n' "//src/ad/..." ;;
    src/fraud-detection/*) printf '%s\n' "//src/fraud-detection/..." ;;
    src/frontend-proxy/*) printf '%s\n' "//src/frontend-proxy/..." ;;
    src/image-provider/*) printf '%s\n' "//src/image-provider/..." ;;
    src/react-native-app/*) printf '%s\n' "//src/react-native-app/..." ;;
    pb/*|tools/bazel/*|MODULE.bazel|.bazelrc|.bazelversion)
      printf '%s\n' "//:smoke" "//pb/..."
      ;;
  esac
}

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

while IFS= read -r path; do
  [[ -z "${path}" ]] && continue
  map_path_to_targets "${path}" >>"${TMP}" || true
done < <(git diff --name-only "${BASE}" "${HEAD}" 2>/dev/null || true)

sort -u "${TMP}"
