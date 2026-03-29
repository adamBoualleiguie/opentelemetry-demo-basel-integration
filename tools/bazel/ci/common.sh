# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# Shared helpers for tools/bazel/ci/*.sh (BZ-611 / M4).

set -euo pipefail

# Repository root (directory containing MODULE.bazel).
bazel_ci_repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  if [[ ! -f "${here}/MODULE.bazel" ]]; then
    echo "common.sh: MODULE.bazel not found above ${BASH_SOURCE[0]}" >&2
    exit 1
  fi
  printf '%s' "${here}"
}

# Prefer bazelisk when available.
bazel_ci_bazel() {
  if command -v bazelisk >/dev/null 2>&1; then
    printf '%s' "bazelisk"
  else
    printf '%s' "bazel"
  fi
}
