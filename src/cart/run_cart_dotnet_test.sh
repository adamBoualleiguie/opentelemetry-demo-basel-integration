#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# BZ-081 / M4: Run xUnit tests for cart (dotnet test) in a temp tree with pb/demo.proto layout.
set -euo pipefail

_cart_resolve_runfiles_root() {
  if [[ -n "${TEST_SRCDIR:-}" ]]; then
    for _base in "${TEST_SRCDIR}"/*; do
      [[ -d "${_base}" ]] || continue
      if [[ -f "${_base}/src/cart/src/cart.csproj" && -f "${_base}/src/cart/tests/cart.tests.csproj" ]]; then
        printf '%s' "${_base}"
        return 0
      fi
    done
  fi
  return 1
}

_proto_resolve() {
  if [[ -n "${TEST_SRCDIR:-}" ]]; then
    local f
    f="$(find "${TEST_SRCDIR}" -path '*/pb/demo.proto' 2>/dev/null | head -n 1)"
    if [[ -n "${f}" && -f "${f}" ]]; then
      printf '%s' "${f}"
      return 0
    fi
  fi
  return 1
}

ROOT_RUNFILES="$(_cart_resolve_runfiles_root)" || {
  echo "run_cart_dotnet_test: could not find src/cart under TEST_SRCDIR=${TEST_SRCDIR:-}" >&2
  exit 1
}
CART_SRC="${ROOT_RUNFILES}/src/cart"
PROTO="$(_proto_resolve)" || {
  echo "run_cart_dotnet_test: could not find pb/demo.proto under TEST_SRCDIR" >&2
  exit 1
}

_try_dotnet_dir() {
  local base="$1"
  [[ -z "${base}" ]] && return 1
  [[ -x "${base}/dotnet" ]] || return 1
  local ver
  ver="$("${base}/dotnet" --version 2>/dev/null)" || return 1
  case "${ver}" in 10.*) printf '%s' "${base}" && return 0 ;; esac
  return 1
}

_pick_sdk10() {
  _try_dotnet_dir "${DOTNET_ROOT:-}" && return 0
  [[ -n "${HOME:-}" ]] && _try_dotnet_dir "${HOME}/.dotnet" && return 0
  local pw_home
  pw_home="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)"
  [[ -n "${pw_home}" ]] && _try_dotnet_dir "${pw_home}/.dotnet" && return 0
  _try_dotnet_dir "/usr/share/dotnet" && return 0
  return 1
}

SDK10="$(_pick_sdk10)" || true
if [[ -n "${SDK10}" ]]; then
  export PATH="${SDK10}:${PATH}"
fi

if ! command -v dotnet >/dev/null 2>&1; then
  echo "run_cart_dotnet_test: dotnet not on PATH" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
mkdir -p "${WORK}/pb"
cp -a "${CART_SRC}/." "${WORK}/"
cp "${PROTO}" "${WORK}/pb/demo.proto"

_H="$(mktemp -d)"
trap 'rm -rf "${WORK}" "${_H}"' EXIT
export HOME="${_H}"
export DOTNET_CLI_HOME="${_H}/.dotnet"
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
mkdir -p "${DOTNET_CLI_HOME}"

cd "${WORK}"
dotnet test tests/cart.tests.csproj -c Release --verbosity minimal --nologo
