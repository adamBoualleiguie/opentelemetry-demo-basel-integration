# M1 completion report — Protobuf graph in Bazel

This document records **what was implemented** for milestone **M1** from `5-bazel-migration-task-backlog.md`:

> **M1:** Proto graph in Bazel; CI protobuf gate uses Bazel **(dual-run)** with the existing Docker/Make flow.

---

## Global summary

- **`pb/demo.proto`** is wired as a Bazel **`proto_library`** (`//pb:demo_proto`).
- **Go + gRPC** codegen is implemented with **`rules_go`** `go_proto_library` for the **two** module import paths used in this repo:
  - **checkout:** `github.com/open-telemetry/opentelemetry-demo/src/checkout/genproto/oteldemo`
  - **product-catalog:** `github.com/opentelemetry/opentelemetry-demo/src/product-catalog/genproto/oteldemo`  
  (Same `.proto`, two `go_package`-equivalent output trees, matching upstream’s quirky dual module path.)
- A **`filegroup`** `//pb:go_grpc_protos` builds **both** Go targets in one CI invocation.
- **CI dual-run (BZ-038):** after `make clean docker-generate-protobuf` and `make check-clean-work-tree`, **`component-build-images.yml`** runs **`bazelisk build //pb:demo_proto //pb:go_grpc_protos --config=ci`**. The legacy gate remains **blocking**; Bazel is **also** blocking if it fails.
- **Checks** job **`bazel_smoke`** (still `continue-on-error: true`) now builds **`//pb:demo_proto`** and **`//pb:go_grpc_protos`** in addition to **`//:smoke`**.
- **Python / Java / C++ / TypeScript** protobuf rules were **not** added to the default module graph (they pull large toolchains). Placeholder notes live in **`pb/extra/README.md`**; policy in **`docs/bazel/proto-policy.md`**.

---

## Per-task status (backlog Epic D)

| ID | Task | Status | Notes |
|----|------|--------|--------|
| **BZ-030** | `pb/BUILD.bazel` `proto_library` | **Done** | `//pb:demo_proto` |
| **BZ-031** | Go gRPC codegen | **Done** | `//pb:demo_go_proto_checkout`, `//pb:demo_go_proto_product_catalog`, bundled as `//pb:go_grpc_protos` |
| **BZ-032** | Python grpc codegen | **Deferred** | Still via Docker/Make; see `pb/extra/README.md` |
| **BZ-033** | TS / `ts_proto` | **Deferred** | Frontend still uses existing `protos/` + npm script |
| **BZ-034** | Java / Kotlin | **Deferred** | `ad` / `fraud-detection` still Gradle; add `java_proto_library` + grpc-java when MODULE is extended |
| **BZ-035** | C++ (`currency`) | **Deferred** | Docker genproto path unchanged; add `cc_proto_library` + grpc C++ in `pb/extra` or dedicated package |
| **BZ-036** | .NET | **Deferred** | Accounting/cart protos still copied via existing flows |
| **BZ-037** | Drift / regeneration policy | **Done** | Documented in **`docs/bazel/proto-policy.md`** (transitional: committed gen + Bazel proof) |
| **BZ-038** | CI protobuf gate dual-run | **Done** | **`component-build-images.yml`** `protobufcheck` job |

---

## Module and toolchain pins (`MODULE.bazel`)

| Dependency | Purpose |
|------------|---------|
| `protobuf` (BCR **29.3**) | `proto_library`, descriptor set, protoc toolchain |
| `rules_go` (**0.53.0**) | `go_proto_library`, `go_proto` + `go_grpc_v2` compilers |
| `gazelle` (**0.42.0**) | Reserved for future `go_deps` / repo generation |
| **Go SDK** | **1.24.5** via `go_sdk.download` (close to service `go.mod` 1.25; adjust when BCR/SDK supports 1.25 cleanly) |

Run after edits:

```bash
bazelisk mod tidy
```

---

## Key Bazel targets

| Target | Meaning |
|--------|---------|
| `//pb:demo_proto` | Descriptor + proto graph root |
| `//pb:demo_go_proto_checkout` | Compiled Go protobuf + gRPC for checkout import path |
| `//pb:demo_go_proto_product_catalog` | Same for product-catalog import path |
| `//pb:go_grpc_protos` | `filegroup` that forces both Go targets to build |

**Local verification:**

```bash
bazelisk build //pb:demo_proto //pb:go_grpc_protos --config=ci
```

---

## Files added or changed (inventory)

| Path | Action |
|------|--------|
| `MODULE.bazel` | Updated (`protobuf`, `rules_go`, `gazelle`, `go_sdk`) |
| `MODULE.bazel.lock` | Regenerated (`bazel mod tidy`) |
| `pb/BUILD.bazel` | Added |
| `pb/extra/README.md` | Added (deferral note for other languages) |
| `docs/bazel/proto-policy.md` | Added (BZ-037) |
| `docs/bazel/milestones/m1-completion.md` | Added (this file) |
| `docs/bazel/README.md` | Updated (milestone links) |
| `.github/workflows/component-build-images.yml` | `protobufcheck`: Bazel proto build step |
| `.github/workflows/checks.yml` | `bazel_smoke`: build `//pb:...` |
| `docs/bazel/charter.md`, `docs/bazel/risk-register.md`, `.bazelrc` | Path fixes for `milestones/` |

---

## Compiler note (rules_go)

Older docs reference `//proto:go_grpc_compiler`. **rules_go 0.53** uses:

- `@rules_go//proto:go_proto`
- `@rules_go//proto:go_grpc_v2` (aligns with `protoc-gen-go-grpc` / `grpc-go` v2 stubs)

---

## Next steps (M2 preview)

1. **`src/checkout` / `src/product-catalog` `BUILD.bazel`:** `go_binary` depending on `//pb:demo_go_proto_*` instead of checked-in `genproto` (optional: stop committing generated Go).
2. **Optional drift test** between Bazel outputs and `src/*/genproto/oteldemo/*.go`.
3. **Extend `MODULE.bazel` + `pb/extra`** for `py_proto_library`, `java_proto_library`, `cc_proto_library`, and later TS.

---

## Related documents

| Document | Role |
|----------|------|
| `5-bazel-migration-task-backlog.md` | Full BZ IDs |
| `docs/bazel/proto-policy.md` | BZ-037 policy |
| `2-bazel-architecture-otel-shop-demo.md` | Target architecture |
| `milestones/m0-completion.md` | Prior milestone |

---

*M1 closed: Bazel owns a minimal, CI-gated proto graph for Go; Docker/Make remain the committed-gen source of truth until M2.*
