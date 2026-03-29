# 32 — Make wrappers, contributor quickstart, and notes I wish every fork had

**Previous:** [`31-remote-cache-bazelrc-user-and-ci-secrets.md`](./31-remote-cache-bazelrc-user-and-ci-secrets.md)

Muscle memory beats README archaeology. I added **thin Makefile targets** so my fingers do not forget paths — they mirror what **`bazel_ci`** runs, just shorter.

---

## Makefile targets

```makefile
# Thin wrappers — same entrypoints as CI.
.PHONY: bazel-check-oci-allowlist bazel-test-unit bazel-ci-fast bazel-ci-full
bazel-check-oci-allowlist:
	python3 ./tools/bazel/policy/check_oci_allowlist.py

bazel-test-unit:
	bazelisk test //... --config=ci --config=unit --build_tests_only

bazel-ci-fast:
	bash ./tools/bazel/ci/ci_fast.sh

bazel-ci-full:
	bash ./tools/bazel/ci/ci_full.sh
```

---

## Two-minute quickstart (if you have the fork checked out)

**Prerequisites** — match the **`bazel_ci`** job where you touch those languages: **Go**, **Node 22**, **Python**, **.NET 10**, **Elixir / OTP**, **PHP + Composer**, **Docker** (for **`oci_load`**), plus **Bazelisk** (`bazel` → Bazelisk).

| Goal | Command |
|------|---------|
| Fast loop (no heavy **`oci_image`** builds) | `make bazel-ci-fast` or `bash ./tools/bazel/ci/ci_fast.sh` |
| Full CI parity (build + unit tests + `//:lint`) | `make bazel-ci-full` or `bash ./tools/bazel/ci/ci_full.sh` |
| Unit tests only | `make bazel-test-unit` or `bazelisk test //... --config=ci --config=unit --build_tests_only` |
| OCI base allowlist check | `make bazel-check-oci-allowlist` |

**Tags:** **`--config=unit`** runs tests tagged **`unit`** and excludes **`integration`**, **`e2e`**, **`manual`**, etc. New **`sh_test` / `go_test` / `js_test`** targets need explicit tags so the unit sweep stays meaningful.

**Release images (Bazel):** push pattern is **`bazel run //src/checkout:checkout_push -- --repository … --tag …`** after registry auth; release automation lives in the **`Bazel checkout OCI (release)`** workflow with optional secret **`BAZEL_CHECKOUT_PUSH_REPOSITORY`**.

**Remote cache (optional):** gitignored **`.bazelrc.user`** loaded via **`try-import`** in **`.bazelrc`**; never commit API keys.

---

## CONTRIBUTING-style Bazel notes (inlined)

If you maintain a **CONTRIBUTING** file next to this migration, these are the bullets I actually want newcomers to see:

- Tests use **tags** (`unit`, `integration`, `e2e`, …). Use **`--config=unit`** for fast tests; **untagged tests do not run** under that config.  
- PR checks run **`bash ./tools/bazel/ci/ci_full.sh`**. For a quicker loop (skips most **`oci_image`** builds), use **`bash ./tools/bazel/ci/ci_fast.sh`** or **`make bazel-ci-fast`** — you still need the same language toolchains where those packages are built (e.g. **Composer** for quote, **Elixir** for flagd-ui).  
- **Proto / Go codegen:** prefer **`bazel run //:gazelle`** and **`//pb:*`** targets over ad-hoc scripts where possible.  
- **Optional remote cache:** **`.bazelrc.user`** (see the **remote cache** article in this series).

This is how you stop answering the same chat question forty times.

```mermaid
flowchart LR
  MK[make bazel-ci-full]
  SH[ci_full.sh]
  BZ[bazel build + test + lint]
  MK --> SH --> BZ
```

---

## Interview line

> “I don’t rely on tribal knowledge for **CI entrypoints** — **Make targets** and **one shell script** mirror **Actions**, and **CONTRIBUTING** states the **tag contract** explicitly.”

---

**Next:** [`33-cypress-tracetest-and-what-i-deferred-on-purpose.md`](./33-cypress-tracetest-and-what-i-deferred-on-purpose.md)
