# Bazel quickstart (BZ-810 / M5)

Short paths for contributors using this fork’s Bazel migration. Canonical references: **`docs/bazel/milestones/m4-completion.md`**, **`m5-completion.md`**, **`docs/bazel/test-tags.md`**.

## Prerequisites

Match **`.github/workflows/checks.yml`** → **`bazel_ci`** where you touch those languages: **Go**, **Node 22**, **Python**, **.NET 10**, **Elixir / OTP**, **PHP + Composer**, **Docker** (for `oci_load`), plus **Bazelisk** (`bazel` → Bazelisk).

## Everyday commands

| Goal | Command |
|------|---------|
| Fast loop (no heavy `oci_image` builds) | `make bazel-ci-fast` or `bash ./tools/bazel/ci/ci_fast.sh` |
| Full CI parity (build + unit tests + `//:lint`) | `make bazel-ci-full` or `bash ./tools/bazel/ci/ci_full.sh` |
| Unit tests only | `make bazel-test-unit` or `bazelisk test //... --config=ci --config=unit --build_tests_only` |
| OCI base allowlist check (BZ-720) | `make bazel-check-oci-allowlist` |

## Tags and configs

- **`--config=unit`** (`.bazelrc` → `test:unit`) runs tests tagged **`unit`** and excludes **`integration`**, **`e2e`**, **`manual`**, etc.  
- Add or adjust tags when introducing new **`sh_test` / `go_test` / …** so **`bazel test //... --config=unit`** stays meaningful.

## Release images (Bazel)

- Push pattern: **`docs/bazel/oci-registry-push.md`**.  
- GitHub Actions: **`.github/workflows/bazel-release-oci.yml`** (checkout image, SBOM, optional push via **`BAZEL_CHECKOUT_PUSH_REPOSITORY`**).

## Remote execution cache (optional)

See **`docs/bazel/remote-cache.md`** for **`--remote_cache`** overrides (BZ-800).
