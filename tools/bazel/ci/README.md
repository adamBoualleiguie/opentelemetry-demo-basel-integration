# Bazel CI scripts (BZ-611 / M4)

Shell entrypoints used locally and from **`.github/workflows/checks.yml`** so **GitHub Actions** and developers run the **same** Bazel graphs.

## Scripts

| Script | Purpose |
|--------|---------|
| **`common.sh`** | Resolves repo root and prefers **`bazelisk`** over **`bazel`**. Sourced by the others; do not run alone. |
| **`ci_full.sh`** | **Full** CI graph: **BZ-720** allowlist check, protos, migrated binaries, **all** **`oci_image`** targets in the smoke set, **`bazel test //... --config=unit --build_tests_only`**, **`bazel run //:lint`**. Parity with the pre-M4 inline **`bazel_smoke`** job. |
| **`ci_fast.sh`** | **Faster** loop: allowlist check, protos, smoke, libraries/publish trees, **`bazel test //... --config=unit --build_tests_only`**, **no** heavy OCI image builds (skips **`frontend_image`**, **`*_oci_image`**, etc.). Use before push when you only changed logic/tests. |
| **`affected_targets.sh`** | **BZ-612** heuristic: given two git refs, prints suggested **`//pkg/...`** patterns for tests. Does **not** replace **`ci_full.sh`** in CI until trusted. |

## Usage

From the repository root:

```bash
chmod +x tools/bazel/ci/*.sh tools/bazel/policy/*.sh src/cart/run_cart_dotnet_test.sh   # once, if needed
./tools/bazel/ci/ci_full.sh
./tools/bazel/ci/ci_fast.sh
./tools/bazel/ci/affected_targets.sh origin/main HEAD
make bazel-ci-full   # Makefile wrapper (BZ-811)
```

## CI cache (BZ-613)

**`.github/workflows/checks.yml`** caches **`~/.cache/bazel`** keyed on **`.bazelversion`** + **`MODULE.bazel.lock`**. Refresh **BZ-003** baselines after tuning.

## Related documentation

- **`docs/bazel/milestones/m4-completion.md`**
- **`docs/bazel/milestones/m5-completion.md`**
- **`docs/bazel/quickstart.md`**
- **`docs/bazel/oci-registry-push.md`**
- **`docs/bazel/oci-base-allowlist.md`**
