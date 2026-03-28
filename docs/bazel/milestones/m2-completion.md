# M2 completion report — First language wave (Go + Node)

This document records **what was implemented** for milestone **M2** from `5-bazel-migration-task-backlog.md`:

> **M2:** First language wave (**Go + one more**) fully **buildable** / **testable** in Bazel.

---

## Global summary

| Area | Outcome |
|------|---------|
| **Go — `checkout`** | `go_library` + `go_binary` from Gazelle; tests under `bazel test //src/checkout/...`. |
| **Go — `product-catalog`** | Same pattern; `bazel build` / `test` for `//src/product-catalog/...`. |
| **Node — `payment`** | **`aspect_rules_js`**: `npm_translate_lock` from **`src/payment/pnpm-lock.yaml`** (generated from existing **`package-lock.json`** via `pnpm import`), `npm_link_all_packages`, **`js_binary`** `//src/payment:payment`. |
| **Protos + Node** | `//pb:demo_proto_js` (`js_library` wrapping `demo.proto`) so cross-package data satisfies rules_js **copy_to_bin** rules; `index.js` resolves the proto path for **Docker** (sibling file) vs **Bazel runfiles** (`_main/pb/demo.proto`). |
| **OpenTelemetry in payment** | `require('./opentelemetry.js')` at the top of `index.js` so the SDK loads before other requires when **not** using Docker’s `node --require` (module cache avoids double-initialization if both run). |
| **Toolchains** | **rules_go 0.59.0** + **gazelle 0.48.0** for **Go 1.25**; **go_sdk.download(1.25.0)**; **aspect_rules_js 2.3.0** + **rules_nodejs** with **Node 22.14.0** (aligned with the payment **Dockerfile** Node 22 line). |
| **CI (`bazel_smoke`)** | Builds **Go services** and **`//src/payment:payment`**, runs **Go tests**, in addition to M0/M1 targets (still **`continue-on-error: true`**). |
| **Test tags (BZ-130)** | Go **`go_test`** targets use **`tags = ["unit"]`**; run **`bazel test ... --config=unit`** per **`.bazelrc`**. Documented in **`docs/bazel/test-tags.md`** (**M3** epic N, applied across milestones). |

---

## Per-task status (backlog)

### Epic E — Go (M2)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| **BZ-040** | `src/checkout` BUILD / binary / tests | **Done** | `bazel build //src/checkout/...`, `bazel test //src/checkout/...` |
| **BZ-041** | `src/product-catalog` | **Done** | Same commands under `//src/product-catalog/...` |
| **BZ-042** | Go toolchain strategy | **Done** | **`docs/bazel/go-toolchain.md`** |

### Epic F — Node (M2)

| ID | Task | Status | Notes |
|----|------|--------|-------|
| **BZ-050** | `src/payment` lockfile + BUILD + runnable target | **Done** | **`package-lock.json`** retained; **`pnpm-lock.yaml`** added for rules_js; **`//src/payment:payment`** |

---

## How it works (reader-oriented)

### 1) Go: Gazelle + `go.work` + Bazel deps

1. **`go.work`** at the repo root includes the two Go modules (`checkout`, `product-catalog`).
2. **`MODULE.bazel`** uses **`go_deps.from_file(go_work = "//:go.work")`** so third-party modules become Bazel **`@go_deps`** repositories (names like `@com_github_ibm_sarama//...`).
3. **`go_sdk.download(version = "1.25.0")`** pins the Go toolchain for builds **and** for tooling that runs during dependency fetch.
4. **`//:gazelle`** (root `BUILD.bazel`) regenerates `BUILD.bazel` files:
   ```bash
   bazel run //:gazelle -- update src/checkout src/product-catalog
   ```
5. Each service **`BUILD.bazel`** keeps **Gazelle directives** so generated code under `genproto/` is **not** double-built, and imports map to **`//pb:demo_go_proto_*`**.

**Expert note:** If `go_repository` fetch fails with “requires go >= 1.25” while an older `go` is used, or stdlib fails with **`unknown GOEXPERIMENT`**, see **`docs/bazel/go-toolchain.md`** (rules_go version + downloaded SDK).

### 2) Node: pnpm lock as the Bazel input

**aspect_rules_js** is built around **pnpm’s** dependency graph. This repo already had **`package-lock.json`**. We added **`pnpm-lock.yaml`** with:

```bash
cd src/payment && pnpm import   # or npx pnpm@8 import on older Node hosts
```

**`npm_translate_lock`** in `MODULE.bazel` points at **`//src/payment:pnpm-lock.yaml`** and lists **`package.json`** in **`data`**. **`bazel mod tidy`** populates **`use_repo(npm, "npm", ...)`** as needed.

In **`src/payment/BUILD.bazel`**, **`npm_link_all_packages`** exposes `node_modules` to **`js_binary`**.

### 3) Proto file path for gRPC loader

`protoLoader.loadSync('demo.proto')` assumes a **file next to the process** in Docker. In Bazel, the proto lives under **`pb/`** in runfiles. **`index.js`** uses a small resolver: same-directory first (Docker), then **`../../pb/demo.proto`** relative to the linked `src/payment` sources in runfiles (Bazel).

### 4) `js_library` in `pb/`

rules_js requires same-package copying for files used as `data` from another package. **`//pb:demo_proto_js`** wraps **`demo.proto`** and is a **`deps`/`data` edge** from **`//src/payment:payment`**.

---

## Commands to verify locally

```bash
# Go
bazel build //src/checkout/... //src/product-catalog/...
bazel test  //src/checkout/... //src/product-catalog/...

# Node
bazel build //src/payment:payment
PAYMENT_PORT=8080 bazel run //src/payment:payment

# M1 + M2 smoke (subset of CI)
bazel build //:smoke //pb:demo_proto //pb:go_grpc_protos \
  //src/checkout/... //src/product-catalog/... //src/payment:payment --config=ci
```

---

## Follow-ups (out of M2 scope)

- **protobufcheck** job could additionally build **`//src/payment:payment`** for parity with **`bazel_smoke`** (trade-off: cold npm fetch time).
- **Gazelle / go_deps** may print a DEBUG line about a missing sum for an internal module; builds still succeed. Clean up when upstream Gazelle/rules_go tighten that path.
- **More Node services** (e.g. **BZ-051** frontend): repeat the pnpm lock + package `BUILD` pattern or adopt a workspace-wide npm/pnpm root.

---

## Related files

| File | Role |
|------|------|
| `MODULE.bazel` | `rules_go`, `gazelle`, `go_sdk`, `go_deps`, `aspect_rules_js`, `npm_translate_lock`, `node.toolchain` |
| `go.work` | Go workspace for checkout + product-catalog |
| `BUILD.bazel` (root) | `//:gazelle` |
| `src/checkout/BUILD.bazel`, `src/product-catalog/BUILD.bazel` | Gazelle-generated Go targets + directives |
| `src/payment/BUILD.bazel` | `npm_link_all_packages`, `js_binary` |
| `src/payment/pnpm-lock.yaml` | rules_js lock input |
| `pb/BUILD.bazel` | `demo_proto_js` for payment |
| `.bazelrc` | `GOEXPERIMENT` clearing; **`test:unit`** / **`test:integration`** (BZ-130) |
| `docs/bazel/test-tags.md` | BZ-130 tag convention and contributor rules |
| `.github/workflows/checks.yml` | `bazel_smoke` M2 steps |
| `docs/bazel/go-toolchain.md` | BZ-042 detail |
| `docs/bazel/service-tracker.md` | Service-level status |
