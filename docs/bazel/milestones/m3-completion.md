# M3 milestone — majority of application services in Bazel (alignment & conversion playbook)

This document is the **M3 milestone report** for `5-bazel-migration-task-backlog.md`. It does three things:

1. **Restates** every backlog task that targets **M3** (with epic and acceptance criteria).  
2. **Explains**, **per application or epic**, how conversion to Bazel is intended to work: stack, today’s entrypoints, ordered steps, proto alignment, tests, and images.  
3. **States honestly** what is **already implemented in this repository** versus **still to do** (so “completion” means *milestone scope covered by the plan*, not that every line item is finished in tree).

> **Backlog definition — M3:**  
> *“Majority of application services build in Bazel; images for migrated services via Bazel.”*

---

## Table of contents

1. [M3 backlog task matrix](#1-m3-backlog-task-matrix)  
2. [High-level status in this fork](#2-high-level-status-in-this-fork)  
3. [Carryover from M2 (foundation for M3)](#3-carryover-from-m2-foundation-for-m3)  
4. [Epic G — Python (BZ-060, BZ-061)](#4-epic-g--python-bz-060-bz-061)  
5. [Epic H — JVM: Java & Kotlin (BZ-070, BZ-071)](#5-epic-h--jvm-java--kotlin-bz-070-bz-071)  
6. [Epic I — .NET (BZ-080)](#6-epic-i--net-bz-080)  
7. [Epic J — Rust (BZ-090)](#7-epic-j--rust-bz-090)  
8. [Epic F — Node: frontend (BZ-051)](#8-epic-f--node-frontend-bz-051)  
9. [Epic M — OCI images (BZ-120, BZ-121)](#9-epic-m--oci-images-bz-120-bz-121)  
10. [Epic N — Test taxonomy (BZ-130)](#10-epic-n--test-taxonomy-bz-130)  
11. [Suggested order inside M3](#11-suggested-order-inside-m3)  
12. [Verification cheat sheet](#12-verification-cheat-sheet)

---

## 1. M3 backlog task matrix

| Epic | ID | Task (short) | Milestone | Acceptance criteria (from backlog) |
|------|-----|----------------|-----------|-------------------------------------|
| **G** | **BZ-060** | Pin Python requirements strategy | M3 | One service (`recommendation` or `product-reviews`) fully buildable in Bazel. Depends on **BZ-032**, python rules. |
| **G** | **BZ-061** | `recommendation`, `product-reviews`, `llm`, `load-generator` | M3 | Each listed service has `bazel build` target; tests where they exist. Depends on **BZ-060**. |
| **H** | **BZ-070** | `ad` — Java | M3 | Prefer `java_binary` / `java_library`; transitional `genrule` + `./gradlew` only if needed. Artifact equivalent to Gradle `installDist` or Docker build stage. Depends on **BZ-034**. |
| **H** | **BZ-071** | `fraud-detection` — Kotlin / fat JAR | M3 | Shadow JAR or equivalent buildable via Bazel. Depends on **BZ-034**, kotlin rules. |
| **I** | **BZ-080** | `accounting` — .NET | M3 | `rules_dotnet` or wrapper around `dotnet publish` with declared outputs; suitable for OCI layer. Depends on **BZ-036** or proto policy. |
| **I** | **BZ-081** | `cart` + tests | **M4** | Listed for context only; not M3. |
| **J** | **BZ-090** | `shipping` — Rust | M3 | `rust_library` / `rust_binary`, tests; Cargo.toml integration; proto if applicable. `bazel build` + `bazel test` for shipping. |
| **F** | **BZ-051** | `frontend` — Next.js | M3 | Build and lint under Bazel; document Next.js + Bazel caveats. |
| **M** | **BZ-120** | Choose OCI rule stack + base policy | M3 | ADR or doc; one pilot image (**BZ-121**). |
| **M** | **BZ-121** | Pilot image (`checkout` or `payment`) | M3 | `docker load` or registry push dry-run documented. |
| **M** | **BZ-122** | Roll out images per service | **M4** | Not M3. |
| **N** | **BZ-130** | Global test tag convention | M3 | Documented; `.bazelrc` examples for filters. Depends on **BZ-013**. |
| **N** | **BZ-131**–**133** | Cypress, Tracetest, consolidate unit tests | M4–M5 | Out of M3 strict scope; noted for sequencing. |

**Proto dependencies called out by backlog:** **BZ-032** (Python grpc), **BZ-034** (Java/Kotlin), **BZ-036** (.NET) — these tie M3 services to the central `pb/demo.proto` story from M1 (`docs/bazel/proto-policy.md`).

---

## 2. High-level status in this fork

| Area | Backlog | In-repo today |
|------|---------|----------------|
| Go `checkout`, `product-catalog` | M2 (BZ-040/041) | **Built & tested** under Bazel (M2). M3 uses them for **BZ-121** pilot candidate. |
| Node `payment` | M2 (BZ-050) | **`js_binary`** (M2). Pilot candidate for **BZ-121**. |
| Python ×4 | M3 (BZ-060/061) | **Not started** — no `BUILD.bazel` under those `src/*` trees yet. |
| Java `ad`, Kotlin `fraud-detection` | M3 (BZ-070/071) | **Not started** — Gradle remains source of truth. |
| .NET `accounting` | M3 (BZ-080) | **Not started**. |
| Rust `shipping` | M3 (BZ-090) | **Not started**. |
| Next `frontend` | M3 (BZ-051) | **Not started**. |
| OCI policy | M3 (BZ-120) | **Documented** in `docs/bazel/oci-policy.md` (**rules_oci** direction, pilot scope). |
| Pilot OCI image | M3 (BZ-121) | **Implemented** for **`checkout`**: `//src/checkout:checkout_image`, `//src/checkout:checkout_load` (see [§9](#9-epic-m--oci-images-bz-120-bz-121)). |
| Test tags | M3 (BZ-130) | **Done**: `.bazelrc` configs; all **`go_test`** targets tagged; **`docs/bazel/test-tags.md`**; **CONTRIBUTING** pointer. |

So: **M3 in this document = full methodological coverage + backlog alignment**; **implementation** of every service is **incremental** after M2.

---

## 3. Carryover from M2 (foundation for M3)

These are **not new M3 epics** but **prerequisites** the backlog assumes before “majority of services” and **BZ-121**.

| Service | Stack | Bazel pattern (done) | Role in M3 |
|---------|-------|----------------------|------------|
| **`src/checkout`** | Go | `go_library` / `go_binary`; Gazelle; `go_deps` from `go.work`; protos → `//pb:demo_go_proto_checkout`; **BZ-121** `oci_image` + `oci_load` | Extend with **tags** and more **`go_test`**; image rollout pattern for other services (**BZ-122**). |
| **`src/product-catalog`** | Go | Same with `//pb:demo_go_proto_product_catalog` | Same as checkout. |
| **`src/payment`** | Node | `aspect_rules_js`: `npm_translate_lock`, `npm_link_all_packages`, `js_binary` | Layer **Node** + runfiles into **oci_image**; match **Dockerfile** env/cmd. |

**Conversion steps (already applied in M2 — summary):**

1. Declare **rules** in `MODULE.bazel` (`rules_go` + `gazelle`; `aspect_rules_js` + `rules_nodejs` + `npm` extension).  
2. **Pin toolchains** (`go_sdk.download`, `node.toolchain`).  
3. **Lockfiles:** `go.work` / `go.mod`; `pnpm-lock.yaml` for payment.  
4. **Per-package `BUILD.bazel`:** Gazelle update for Go; manual/js rules for payment.  
5. **Proto:** `go_proto_library` in `pb/`; `js_library` `//pb:demo_proto_js` for Node loader.  
6. **CI:** `bazel_smoke` subset (`checks.yml`).

---

## 4. Epic G — Python (BZ-060, BZ-061)

### 4.1 BZ-060 — Requirements strategy (once per repo or per service)

**Goal:** Hermetic or semi-hermetic Python builds that Bazel can cache.

**Recommended pattern:**

1. **Lock** dependencies: `requirements.txt` (pinned) or **`requirements.lock`** via **pip-tools** / **uv lock** — one file per service or one merged lock with namespaces (trade-off: simpler per-service locks for M3).  
2. Add **`rules_python`** to `MODULE.bazel` (`bazel_dep`).  
3. Use **`pip_parse`** (or `compile_pip_requirements`) to turn the lockfile into **`@pypi//`** (or similar) external repos.  
4. Define a **macro or convention**: `src/<svc>/BUILD.bazel` contains `py_library` + `py_binary` (or `py_console_script_binary`) with `deps` from `@pypi//...`.

**Status:** Not wired in `MODULE.bazel` yet.

---

### 4.2 Service: `src/recommendation`

| Field | Detail |
|-------|--------|
| **Stack** | Python gRPC service, **`requirements.txt`** (grpc, OpenTelemetry, FlagD provider, etc.). |
| **Build today** | Docker multi-stage; `python` in container. |
| **Proto** | Consumer (**BZ-032**): generated `*_pb2.py` / gRPC stubs should come from Bazel `proto_library` + `py_proto_library` / `py_grpc_library` (or codegen rule aligned with `pb/demo.proto`). |
| **Backlog** | **BZ-060** pilot candidate; **BZ-061** must list it as buildable. |

**Conversion steps (target end state):**

1. Add **`proto`** Python codegen under `pb/` (or `pb/extra` if policy keeps default graph small — see `pb/extra/README.md`).  
2. Add **`rules_python`** + **`pip_parse`** pointing at `src/recommendation/requirements.txt` (locked).  
3. Create **`src/recommendation/BUILD.bazel`**:  
   - `py_library` for application modules.  
   - `py_binary` (entry = server main) with `deps` = lib + `@pypi//...` + proto py libs.  
4. **Data/runtime**: `filegroup` or `env` for any config copied in Dockerfile today.  
5. **`py_test`** for any `tests/` or `*_test.py` with `tags = ["unit"]` where appropriate.  
6. **CI**: extend `bazel_smoke` or a dedicated job with `bazel build //src/recommendation:...`.

**Status in this repository:** **Not started**.

---

### 4.3 Service: `src/product-reviews`

| Field | Detail |
|-------|--------|
| **Stack** | Python (similar pattern to recommendation). |
| **Proto** | Yes — align with **BZ-032** same as recommendation. |

**Conversion steps:** Repeat **§4.2** pattern; share the same **`pip_parse`** root if dependency sets overlap, or isolate a second requirements lock for clarity.

**Status in this repository:** **Not started**.

---

### 4.4 Service: `src/llm`

| Field | Detail |
|-------|--------|
| **Stack** | Python; may pull heavier ML stacks — watch wheel/platform tags in `pip_parse`. |
| **Proto** | Per service README / imports; if no gRPC, proto step may be minimal. |

**Conversion steps:** Same as §4.2; validate **large deps** (GPU optional, etc.) against sandbox/network rules in CI.

**Status in this repository:** **Not started**.

---

### 4.5 Service: `src/load-generator`

| Field | Detail |
|-------|--------|
| **Stack** | Python + **Locust** (backlog: may be `py_binary` for Locust). |
| **Build today** | Docker. |

**Conversion steps:**

1. Lock Locust + app deps in `requirements.txt`.  
2. `py_binary` entrypoint = Locust or a thin wrapper script matching `Dockerfile` **CMD**.  
3. Tag tests **`manual`** or **`integration`** if they need live services (**BZ-130** alignment).

**Status in this repository:** **Not started**.

---

## 5. Epic H — JVM: Java & Kotlin (BZ-070, BZ-071)

### 5.1 Service: `src/ad` (Java, Gradle)

| Field | Detail |
|-------|--------|
| **Stack** | **Gradle** (`build.gradle`, `settings.gradle`), Java sources under `src/main/java`. |
| **Build today** | `./gradlew` in Docker; fat/configured JAR for container. |
| **Proto** | **BZ-034**: `java_proto_library` / gRPC Java from `//pb:demo_proto` (or dedicated `java_grpc_library` rules). |
| **Backlog** | **BZ-070** — prefer native **`java_library`** / **`java_binary`** (or **`java_test`**). |

**Conversion steps (preferred path):**

1. Add **`rules_java`**, **`rules_jvm_external`** (Maven pin) or **Gradle-deps export** to `MODULE.bazel`.  
2. Wire **protobuf Java** outputs from `pb/demo.proto` into a single **`java_library`** consumed by `ad`.  
3. Create **`src/ad/BUILD.bazel`**:  
   - `java_library` per package or one merged library mirroring Gradle `sourceSets`.  
   - `java_binary` with `main_class` matching today’s entrypoint (`oteldemo.AdService` or as in Gradle).  
4. **Resources**: `src/main/resources` via `resources = glob(...)` on the library.  
5. **Transitional:** if migration is blocked, **`genrule`** invoking `./gradlew installDist` with **`outs`** declared — backlog allows this **only if needed**.  
6. **Tests:** port Gradle tests to `java_test` when present.

**Status in this repository:** **Not started** (Gradle-only).

---

### 5.2 Service: `src/fraud-detection` (Kotlin)

| Field | Detail |
|-------|--------|
| **Stack** | Kotlin / JVM, typically **Gradle** + **shadow** JAR for images. |
| **Proto** | **BZ-034** + Kotlin gRPC if used. |
| **Backlog** | **BZ-071** — shadow/fat JAR equivalent (`java_binary` deploy jar, or `rules_kotlin` + single deployable). |

**Conversion steps:**

1. Add **`rules_kotlin`** (and Java rules as above).  
2. Kotlin **`kt_jvm_library`** + **`kt_jvm_binary`** or **`java_binary`** runtime entry.  
3. Reproduce **shadow** semantics: prefer **`java_binary`** with **`create_executable = False`** + deploy env, or a **`pkg_tar`** / **`rules_pkg`** staging step for OCI.  
4. Align **OpenTelemetry** / logging JARs via Maven pin (`rules_jvm_external`).

**Status in this repository:** **Not started**.

---

## 6. Epic I — .NET (BZ-080)

### 6.1 Service: `src/accounting`

| Field | Detail |
|-------|--------|
| **Stack** | **.NET** (`Accounting.csproj`, NuGet). |
| **Build today** | `dotnet publish` in Docker. |
| **Proto** | **BZ-036** or copy policy — generated C# from `demo.proto` or shared package. |
| **Backlog** | **BZ-080** — `rules_dotnet` **or** **`genrule`/`run_binary`** wrapping `dotnet publish` with explicit **`outs`**. |

**Conversion steps:**

1. Choose **`rules_dotnet`** on BCR vs **wrapper**: wrapper is faster to greenfield; native rules are better long-term.  
2. If protos: add **`csharp_proto_library`** / gRPC C# rule set consistent with `pb/demo.proto`.  
3. **`src/accounting/BUILD.bazel`**: `dotnet_binary` or genrule output = publish folder.  
4. **Tests:** `dotnet test` mapped to `bazel test` when **BZ-081** extends **cart** (M4).

**Status in this repository:** **Not started**.

---

## 7. Epic J — Rust (BZ-090)

### 7.1 Service: `src/shipping`

| Field | Detail |
|-------|--------|
| **Stack** | **Cargo** (`Cargo.toml`, `edition = "2021"`), **actix-web**, **tonic**, OpenTelemetry crates. |
| **Build today** | `cargo build --release` in Docker. |
| **Proto** | **BZ-030** if gRPC types must come from Bazel: `prost`/`tonic` build from `proto_library` via **`rules_rust`** `rust_proto_library` (or `cargo_build_script` bridge). |
| **Backlog** | **BZ-090** — `rust_binary` + `rust_test`, `cargo` integration. |

**Conversion steps:**

1. Add **`rules_rust`** to `MODULE.bazel`; **`crate_universe`** from `Cargo.toml` (or `cargo_lockfile` import).  
2. Map **workspace** or single-crate layout: `rust_binary(name = "shipping", srcs = ..., deps = ...)` from resolved crates.  
3. **Proto:** either (a) generate from `//pb:demo_proto` in Bazel and depend from `rust_library`, or (b) keep `build.rs` temporarily and declare **`cargo_build_script`** — backlog prefers consistency with **BZ-030** over time.  
4. **`rust_test`** for unit tests under `src/**` with `tags = ["unit"]`.  
5. **CI:** `bazel test //src/shipping/...`.

**Status in this repository:** **Not started**.

---

## 8. Epic F — Node: frontend (BZ-051)

### 8.1 Service: `src/frontend`

| Field | Detail |
|-------|--------|
| **Stack** | **Next.js** / TypeScript, **npm**, large `node_modules`. |
| **Build today** | Docker multi-stage `npm run build` + production server. |
| **Proto** | **BZ-033** (deferred in M1) — TS stubs; today may use checked-in `protos/` + npm script. |

**Conversion steps:**

1. Extend **`aspect_rules_js`** (or add **pnpm workspace**) to include `src/frontend`: new **`pnpm-lock.yaml`** (or monorepo root lock) and **`npm_translate_lock`**.  
2. **`next.js` under Bazel** is non-trivial: common patterns include **`js_run_binary`** for `next build` with declared **`outs`**, or **external Next + Bazel lint-only** first. Backlog asks to **document caveats** (output dirs, env, `NEXT_PUBLIC_*`).  
3. **`js_test` or `jest_test`** for unit tests; **`tags = ["e2e", "manual"]`** for Cypress (**BZ-131**, M4).  
4. **`BUILD.bazel`**: `js_binary` or custom rule for production server matching **Dockerfile** **CMD**.

**Status in this repository:** **Not started**.

---

## 9. Epic M — OCI images (BZ-120, BZ-121)

### 9.1 BZ-120 — Policy

**Done in this fork (doc-level):** `docs/bazel/oci-policy.md` selects **`rules_oci`**, digest-pinned bases, and scopes the pilot to a single service first (**BZ-121**).

### 9.2 BZ-121 — Pilot image (`checkout`)

**Choice:** **`src/checkout`** (Go) — already built as **`//src/checkout:checkout`** in M2; static Linux binary fits **`gcr.io/distroless/static-debian12`** (nonroot).

**Module wiring (`MODULE.bazel`):**

- **`bazel_dep`:** `rules_oci` 2.3.0, `aspect_bazel_lib` 2.21.1, `tar.bzl` 0.7.0 (layer tar + toolchains).
- **`oci.pull`** defines a digest-pinned base repo **`distroless_static_debian12_nonroot`** for **`linux/amd64`** and **`linux/arm64`** (same digest: `sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1`, image `gcr.io/distroless/static-debian12`).
- **Why there is no `oci.toolchains()` in the root module:** the **`rules_oci` module’s own `MODULE.bazel` already calls `oci.toolchains()`**. Bzlmod merges extension tags; a second `oci.toolchains()` from the root duplicated crane repositories and broke analysis. The root module still **`use_repo`**-exports **`oci_crane_toolchains`** and **`oci_regctl_toolchains`** and **`register_toolchains(...)`** for them so crane/regctl are visible from this repo.
- **Supporting toolchains:** `aspect_bazel_lib` **`jq`** + **`zstd`**; **`tar.bzl`** **`bsd_tar_toolchains`** — required by **`rules_oci`** / aspect tar rules.

**Package targets (`src/checkout/BUILD.bazel`):**

| Target | Role |
|--------|------|
| **`checkout_mtree_raw` → `checkout_mtree` → `checkout_layer`** | **`mtree_spec`** / **`mtree_mutate`** / **`tar`** from **`aspect_bazel_lib`**: place the `go_binary` at **`usr/src/app/checkout`** inside a single layer tar. |
| **`checkout_image`** | **`oci_image`**: **`base`** = `@distroless_static_debian12_nonroot_linux_amd64//:distroless_static_debian12_nonroot_linux_amd64`, **`tars`** = `:checkout_layer`, **`entrypoint`** = `["/usr/src/app/checkout"]`, **`workdir`** = `/usr/src/app`, **`exposed_ports`** = `["5050/tcp"]` (aligned with demo **CHECKOUT_PORT** / Dockerfile intent). |
| **`checkout_load`** | **`oci_load`**: produces a **`docker load`**-compatible bundle; **`repo_tags`** = **`otel/demo-checkout:bazel`**. |

**Platform note:** the **`oci_image` `base`** is fixed to **linux/amd64** today so a default **`bazel build`** on an amd64 CI host matches the base without a platform transition. **`oci.pull`** still fetches **arm64** for future multi-arch or Apple Silicon native builds; switching the `base` label to **`..._linux_arm64`** (or using **`platform`** / transitions) is the follow-up when you standardize cross-builds.

**Verification:**

```bash
bazel build //src/checkout:checkout_image --config=ci
bazel build //src/checkout:checkout_load --config=ci
# Load into local Docker (requires Docker CLI):
bazel run //src/checkout:checkout_load
docker image ls | grep otel/demo-checkout
```

**`bazel mod tidy` caveat:** tidy may report **`oci_crane_toolchains`** / **`oci_regctl_toolchains`** as indirect imports. They must stay in **`use_repo(oci, …)`** or analysis fails with “repository not defined”; do not let tidy drop them if builds break.

**Next (out of BZ-121):** replicate the pattern for **`payment`** (Node runfiles + base image matching **`src/payment/Dockerfile`**), then **BZ-122** (per-service rollout and CI parity with **`component-build-images.yml`**).

---

## 10. Epic N — Test taxonomy (BZ-130)

**Backlog acceptance:** documented tag names; `.bazelrc` examples.

**Done in this repository:**

- **`.bazelrc`**: `test:unit`, `test:integration`, `test:e2e`, `test:trace` with `test_tag_filters` (repo root).  
- **`go_test`:** every target carries **`tags = ["unit"]`** today (`//src/checkout/money:money_test` — sole `go_test` in tree).  
- **`docs/bazel/test-tags.md`:** tag meanings, `.bazelrc` usage, contributor rules for future **`go_test` / `py_test` / `rust_test`**.  
- **`CONTRIBUTING.md`:** short “Bazel (migration fork)” pointer to **`.bazelrc`** and **`docs/bazel/test-tags.md`**.

**Convention (for new tests):**

| Tag | Use |
|-----|-----|
| `unit` | Fast, hermetic, default PR. |
| `integration` | Local services / docker-compose (may be `local` executor). |
| `e2e` | Browser / full stack (**frontend**). |
| `trace` | Tracetest (**BZ-132**, later). |
| `slow` | Large timeouts. |
| `manual` | Not run in CI unless explicitly selected. |

**Ongoing:** When adding **`py_test`**, **`rust_test`**, or **`js_test`** under M3+, apply the same tags; Gazelle does not add tags automatically.

---

## 11. Suggested order inside M3

Aligned with **§22 Suggested implementation order** in the backlog (items 8–12, 16 partial):

1. **BZ-120 / BZ-121** — OCI policy + pilot image (proves end-to-end artifact story).  
2. **BZ-051** or **BZ-090** — one “hard” language (Next or Rust) to de-risk.  
3. **BZ-060 / BZ-061** — Python wave starting with **`recommendation`**.  
4. **BZ-070 / BZ-071** — JVM (shared Maven pin helps both).  
5. **BZ-080** — .NET accounting.  
6. **BZ-130** — **Done** (taxonomy + docs); extend tags as new test rules land.

---

## 12. Verification cheat sheet

**Already available (M2 + M1):**

```bash
bazel build //:smoke //pb:demo_proto //pb:go_grpc_protos --config=ci
bazel build //src/checkout/... //src/product-catalog/... //src/payment:payment --config=ci
bazel test  //src/checkout/... //src/product-catalog/... --config=ci
bazel test  //src/checkout/money:money_test --config=unit
bazel test  //... --config=unit   # all tests tagged `unit` (see docs/bazel/test-tags.md)
bazel build //src/checkout:checkout_image //src/checkout:checkout_load --config=ci   # BZ-121 OCI pilot
```

**When M3 services land, extend with:**

```bash
bazel build //src/recommendation:...    # after BZ-060/061
bazel build //src/shipping:...         # after BZ-090
# etc.
```

---

## Related documents

| Document | Purpose |
|----------|---------|
| `5-bazel-migration-task-backlog.md` | Source of truth for task IDs and milestones. |
| `docs/bazel/milestones/m1-completion.md` | Proto graph (M1). |
| `docs/bazel/milestones/m2-completion.md` | Go + payment (M2). |
| `docs/bazel/proto-policy.md` | Proto single source / drift policy. |
| `docs/bazel/go-toolchain.md` | Go SDK / Gazelle (M2). |
| `docs/bazel/oci-policy.md` | BZ-120 OCI direction. |
| `docs/bazel/test-tags.md` | BZ-130 test tag convention. |
| `docs/bazel/service-tracker.md` | Per-service B/T/I/CI snapshot. |

---

*This file should be updated whenever a service moves from “Not started” to buildable: add the concrete target labels, `MODULE.bazel` pins, and CI lines in the relevant section and in `service-tracker.md`.*
