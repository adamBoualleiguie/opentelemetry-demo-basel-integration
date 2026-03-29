#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
exec python3 "$(dirname "${BASH_SOURCE[0]}")/check_oci_allowlist.py"
