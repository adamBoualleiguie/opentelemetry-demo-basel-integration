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
| Node `payment` | M2 (BZ-050) | **`js_binary`** (M2) + **BZ-121** **`payment_image`** / **`payment_load`** (see §9.3). |
| Python ×4 | M3 (BZ-060/061) + **BZ-121** OCI | **Buildable:** `rules_python` + dual **`pip.parse`** hubs; **`//pb:demo_py_grpc`**; **`py_binary`** + **`oci_image`** / **`oci_load`** per service (**§4**, **§9.5**). |
| Java `ad`, Kotlin `fraud-detection` | M3 (BZ-070/071) | **Not started** — Gradle remains source of truth. |
| .NET `accounting` | M3 (BZ-080) | **Not started**. |
| Rust `shipping` | M3 (BZ-090) | **Not started**. |
| Next `frontend` | M3 (BZ-051) | **`next build`** via **`js_run_binary`** **`//src/frontend:next_build`**; **lint** **`//src/frontend:lint`**; **`npm_frontend`** + `pnpm-lock.yaml` (see [§8](#8-epic-f--node-frontend-bz-051)). |
| OCI policy | M3 (BZ-120) | **Documented** in `docs/bazel/oci-policy.md` (**rules_oci** direction, pilot scope). |
| Pilot OCI image | M3 (BZ-121) | **Implemented** for **`checkout`**, **`payment`**, **`frontend`**, and the **four Python** services (**`recommendation`**, **`product-reviews`**, **`llm`**, **`load-generator`**): **`oci_image`** + **`oci_load`** each (see [§9](#9-epic-m--oci-images-bz-120-bz-121)). |
| Test tags | M3 (BZ-130) | **Done**: `.bazelrc` configs; all **`go_test`** targets tagged; **`docs/bazel/test-tags.md`**; **CONTRIBUTING** pointer. |

So: **M3 in this document = full methodological coverage + backlog alignment**; **implementation** of every service is **incremental** after M2.

---

## 3. Carryover from M2 (foundation for M3)

These are **not new M3 epics** but **prerequisites** the backlog assumes before “majority of services” and **BZ-121**.

| Service | Stack | Bazel pattern (done) | Role in M3 |
|---------|-------|----------------------|------------|
| **`src/checkout`** | Go | `go_library` / `go_binary`; Gazelle; `go_deps` from `go.work`; protos → `//pb:demo_go_proto_checkout`; **BZ-121** `oci_image` + `oci_load` | Extend with **tags** and more **`go_test`**; image rollout pattern for other services (**BZ-122**). |
| **`src/product-catalog`** | Go | Same with `//pb:demo_go_proto_product_catalog` | Same as checkout. |
| **`src/payment`** | Node | `aspect_rules_js` + **`js_image_layer`** + **`oci_image`** / **`oci_load`** (BZ-121); **`@opentelemetry/otlp-exporter-base`** declared in **`package.json`** so Node can resolve SDK transitive imports under the pnpm layout | Rollout pattern for other Node services; **BZ-122** CI matrix parity. |

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

**Status:** **Implemented.** `MODULE.bazel` declares **`bazel_dep(rules_python, 0.40.0)`**, default **`python.toolchain`** **3.12**, and two **`pip.parse`** roots: **`hub_name = "pypi"`** → **`//tools/python:requirements_lock.txt`** (gRPC services + **`llm`**), **`hub_name = "pypi_loadgen"`** → **`//tools/python:requirements_loadgen_lock.txt`** (Locust / Playwright stack). **`use_repo(pip, "pypi", "pypi_loadgen")`**. Pin/refresh: **`tools/python/README.md`** ( **`pip-compile`** on **`requirements.in`** / **`requirements_loadgen.in`**, Python **3.12**).

---

### 4.2 Service: `src/recommendation`

| Field | Detail |
|-------|--------|
| **Stack** | Python gRPC service, **`requirements.txt`** (grpc, OpenTelemetry, FlagD provider, etc.). |
| **Build today** | Docker multi-stage; `python` in container. |
| **Proto** | Consumer (**BZ-032**): shared **`//pb:demo_py_grpc`** (`py_library` over committed **`pb/python/demo_pb2*.py`**, aligned with **`pb/demo.proto`** / **`docs/bazel/proto-policy.md`**). |
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

**Status in this repository:** **`//src/recommendation:recommendation`** **`py_binary`**; **`recommendation_image`** / **`recommendation_load`** (**§9.5**). No in-tree **`py_test`** yet (nothing to tag).

---

### 4.3 Service: `src/product-reviews`

| Field | Detail |
|-------|--------|
| **Stack** | Python (similar pattern to recommendation). |
| **Proto** | Yes — align with **BZ-032** same as recommendation. |

**Conversion steps:** Repeat **§4.2** pattern; share the same **`pip_parse`** root if dependency sets overlap, or isolate a second requirements lock for clarity.

**Status in this repository:** **`//src/product-reviews:product_reviews`** **`py_binary`**; **`product_reviews_image`** / **`product_reviews_load`** (**§9.5**).

---

### 4.4 Service: `src/llm`

| Field | Detail |
|-------|--------|
| **Stack** | Python; may pull heavier ML stacks — watch wheel/platform tags in `pip_parse`. |
| **Proto** | None in application code; no **`demo_py_grpc`** dep. |

**Conversion steps:** Same as §4.2; validate **large deps** (GPU optional, etc.) against sandbox/network rules in CI.

**Status in this repository:** **`//src/llm:llm`** **`py_binary`**; **`llm_image`** / **`llm_load`** (**§9.5**). JSON assets via **`data = glob(...)`** and paths resolved relative to **`__file__`** (compatible with Docker’s flat copy). Lock: **`@pypi`**.

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

**Status in this repository:** **`//src/load-generator:load_generator`** **`py_binary`**; **`load_generator_image`** / **`load_generator_load`** (**§9.5** — **no Playwright browsers** in the Bazel image; see **`docs/bazel/oci-policy.md`**). Lock: **`@pypi_loadgen`**.

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
| **Stack** | **Next.js 16** / TypeScript, **pnpm lock** beside the app (same pattern as **`src/payment`**). |
| **Build today** | Docker multi-stage **`npm run build`** + production **`server.js`**; local **`pnpm` / `npm`** workflows unchanged. |
| **Proto** | **BZ-033** (deferred in M1): TS stubs live under **`src/frontend/protos/`** (generated / checked-in). Bazel lint **ignores** **`protos/**`** so we do not edit generated files; long term, align with **`docs/bazel/proto-policy.md`** if codegen moves under **`//pb`**. |

**What we implemented (BZ-051 + BZ-121-style frontend image)**

1. **`MODULE.bazel`** — second **`npm.npm_translate_lock`** instance **`name = "npm_frontend"`** with **`pnpm_lock`** / **`data`** pointing at **`//src/frontend:package.json`** and **`//src/frontend:pnpm-lock.yaml`**, then **`use_repo(npm, "npm", "npm_frontend")`**. This keeps the **huge** Next dependency graph **separate** from **`@npm`** (payment) and avoids merging two apps into one pnpm workspace. **`public_hoist_packages`** hoists **`next`**, **`react`**, **`react-dom`**, **`styled-components`**, and selected **`@openfeature/*`** packages under **`src/frontend`** so Next’s workers tend to resolve a single copy of those frameworks.  
2. **`lifecycle_hooks_exclude = ["cypress"]`** on **`npm_frontend`** so Bazel never runs Cypress’s postinstall (large binary download). **E2E** remains **BZ-131** / Makefile, not CI here.  
3. **`src/frontend/pnpm-lock.yaml`** — **pnpm v8** (**`lockfileVersion: '6.0'`**) for **`npm_translate_lock`**. **`package.json`** declares **`pnpm.overrides`** so **`@connectrpc/connect`** and **`@connectrpc/connect-web`** are intended to use **`@bufbuild/protobuf@1.10.1`** while the app keeps **`@bufbuild/protobuf@^2.11.0`** for **ts-proto** / **`@bufbuild/protobuf/wire`**. The lockfile’s **`/@connectrpc/connect@1.7.0(...)`** stanza is aligned to **`@bufbuild/protobuf@1.10.1`** (pnpm’s resolver can still emit a **`2.11.0`** flavor key without overrides; refresh the lock with **`pnpm install`** when changing Connect / protobuf).  
4. **`src/frontend/BUILD.bazel`** — **`exports_files`** for manifests + locks; **`npm_link_all_packages`**; **`js_test`** **`//src/frontend:lint`**; **`js_binary`** **`next_build_tool`** + **`js_run_binary`** **`next_build`** (outputs **`.next`**); **`copy_to_directory`** / **`tar`** / **`oci_image`** **`frontend_image`** + **`oci_load`** **`frontend_load`** (**`otel/demo-frontend:bazel`**). **`next_build`** is tagged **`manual`** and **`no-sandbox`** (see caveats below).  
5. **`src/frontend/next_build_cli.cjs`** — runs **`next build --webpack`** when **`BAZEL_COMPILATION_MODE`** is set (Turbopack + rules_js symlinks is unstable in the sandbox).  
6. **`src/frontend/bazel_next_worker_shim.cjs`** — patches **`os.cpus()`** to return a single CPU so Next’s “collect page data” pool does not multiply rules_js symlink graphs across workers.  
7. **`src/frontend/eslint_cli.cjs`** — same **`argv`** pattern as other **`rules_js`** CLIs; resolves ESLint 9’s **`bin/eslint.js`** via **`eslint/package.json`**.  
8. **ESLint config** — **`eslint.config.mjs`** (**`eslint-config-next/core-web-vitals`**); legacy **`.eslintrc`** removed (flat config only).  
9. **Rule tuning / source fixes** — as before (hooks purity off, **`protos/**`** ignored, small demo hygiene fixes).  
10. **`MODULE.bazel`** — **`oci.pull`** for **`gcr.io/distroless/nodejs24-debian13:nonroot`** (digest-pinned), matching **`src/frontend/Dockerfile`**, for **`frontend_image`** **`base`**.

**Why not `next lint` inside `js_test`**

Next 16’s **`next`** CLI registers **`dev`** as the default command. **`rules_js`** invokes the entry script with extra trailing arguments; in practice **`lint`** was parsed as the **dev server directory**, not the **`lint`** subcommand. Calling **`eslint`** directly matches what **`next lint`** does under the hood and stays deterministic in the sandbox.

**Next.js + Bazel caveats (`next build` + OCI)**

| Topic | Caveat |
|-------|--------|
| **`NEXT_PUBLIC_*`** | Inlined at **build** time; Bazel must pass stable **`env`** on **`js_run_binary`** if you need parity with Docker for those keys. |
| **`.env`** | Next loads dotenv from the repo (**`../../.env`** in **`next.config.js`**); hermetic CI may still see empty values unless you declare inputs / env. |
| **`next.config.js`** | Under Bazel, **`webpack`** is used for production build (**`--webpack`**); **`turbopack`** is `{}` when **`BAZEL_COMPILATION_MODE`** is set. **React** / **react-dom** **`resolve.alias`** pins a single copy for the bundle. |
| **Outputs** | **`js_run_binary`** declares **`out_dirs = [".next"]`**. **Standalone** traces **`node_modules`** symlinks from rules_js. |
| **`no-sandbox`** | **`//src/frontend:next_build`** uses tag **`no-sandbox`**: under the default sandbox, Bazel rejects **dangling symlinks** inside **`.next/standalone/node_modules`** (links point outside the action). Disabling the sandbox matches how **Docker** sees the same tree. |
| **`NODE_OPTIONS`** | Do not append a second **`--require=...`** via **`env`** on **`js_run_binary`**: **`rules_js`** already preloads **`register.cjs`**, and a merged **`NODE_OPTIONS`** breaks Node’s preload parser. The **worker shim** loads from **`next_build_cli.cjs`** instead. |
| **Connect / protobuf** | **`@openfeature/flagd-web-provider`** pulls **`@connectrpc/connect@1`**, which must resolve **`@bufbuild/protobuf` v1** for its CJS **`Message`** types while the app uses **protobuf v2** for gRPC codegen — see **`pnpm.overrides`** + lockfile **`/@connectrpc/connect@1.7.0(@bufbuild/protobuf@1.10.1)`** stanza. |
| **Cypress** | Excluded from **`npm_frontend`** lifecycle hooks; image **`frontend_image_root`** does not assume a full local **`pnpm install`**. |

**Still deferred**

- **Unit / Jest** as **`js_test`** (only **ESLint** is gated today).  
- **BZ-122** mass rollout / **`component-build-images.yml`** parity (this fork proves **Bazel** path only).

**Verification**

```bash
bazel test //src/frontend:lint --config=ci
bazel build //src/frontend:next_build //src/frontend:frontend_image //src/frontend:frontend_load --config=ci
# optional:
# bazel run //src/frontend:frontend_load
# docker image ls | grep otel/demo-frontend
```

**Status in this repository:** **Implemented** (lint + **`next build`** + **`frontend_image`** / **`frontend_load`** + caveats above).

---

## 9. Epic M — OCI images (BZ-120, BZ-121)

### 9.1 BZ-120 — Policy

**Done in this fork (doc-level):** `docs/bazel/oci-policy.md` selects **`rules_oci`**, digest-pinned bases, and documents **BZ-121** on **checkout** (Go), **payment** (Node / **js_image_layer**), **frontend** (Next + **nodejs24** distroless), and **Python** services (**`rules_pkg`** **`pkg_tar(include_runfiles)`** + **`docker.io/library/python:3.12-slim-bookworm`**).

### 9.2 BZ-121 — Pilot image (`checkout`, Go)

**Choice:** **`src/checkout`** (Go) — already built as **`//src/checkout:checkout`** in M2; static Linux binary fits **`gcr.io/distroless/static-debian12`** (nonroot).

**Module wiring (`MODULE.bazel`):**

- **`bazel_dep`:** `rules_oci` 2.3.0, `aspect_bazel_lib` 2.21.1, `tar.bzl` 0.7.0, **`rules_pkg`** 1.0.1 (Python service **`pkg_tar`** layers).
- **`oci.pull`** defines digest-pinned bases: **`distroless_static_debian12_nonroot`** (checkout), **`distroless_nodejs22_debian12_nonroot`** / **`distroless_nodejs24_debian13_nonroot`** (Node), **`python_312_slim_bookworm`** (Python), each for **`linux/amd64`** and **`linux/arm64`** where applicable (see `MODULE.bazel` for digests).
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

### 9.3 BZ-121 — Extension: **`payment`** (Node)

**What we added**

1. **`MODULE.bazel`** — second **`oci.pull`** for **`gcr.io/distroless/nodejs22-debian12`** (**`:nonroot`**), using the **image index digest** `sha256:13593b7570658e8477de39e2f4a1dd25db2f836d68a0ba771251572d23bb4f8e` so **linux/amd64** and **linux/arm64** variants resolve the same way as other multi-arch pulls. This matches the **runtime** stage of **`src/payment/Dockerfile`** (`gcr.io/distroless/nodejs22-debian12:nonroot`).

2. **`src/payment/BUILD.bazel`** — **`js_image_layer`** from **`aspect_rules_js`** on **`//src/payment:payment`**, with **`root = "/usr/src/app"`** so the runfiles tree lands under the same prefix as the Dockerfile **`WORKDIR`**. **`oci_image`** uses **`filegroup`** + **`output_group`** to stack **package_store_3p**, **package_store_1p**, **node_modules**, and **app** layers **without** the **`node`** layer group, so the image uses the distroless **`/nodejs/bin/node`** binary instead of duplicating the rules_js toolchain.

3. **Entrypoint / CMD** — **`entrypoint = ["/nodejs/bin/node"]`**, **`cmd = ["--require=./opentelemetry.js", "index.js"]`**, **`workdir`** = the directory that contains **`index.js`** inside runfiles (`.../payment.runfiles/_main/src/payment`). That mirrors the Dockerfile **`CMD`** while **`index.js`** still **`require()`s** `./opentelemetry.js` on its own (same as local **`bazel run`**).

4. **`oci_load`** — **`//src/payment:payment_load`** tags the image **`otel/demo-payment:bazel`** for **`docker load`**.

5. **`package.json` / `pnpm-lock.yaml`** — added a **direct** dependency **`@opentelemetry/otlp-exporter-base@0.213.0`**. Under the pnpm virtual-store layout, **`@opentelemetry/sdk-node`** could **`require('@opentelemetry/otlp-exporter-base')`** without a hoisted top-level **`node_modules`** entry; **`bazel run //src/payment:payment`** and the container both failed with **`MODULE_NOT_FOUND`** until this explicit dependency was added. The lockfile was refreshed with **pnpm v8** so **`lockfileVersion: '6.0'`** stays compatible with **`npm_translate_lock`** (pnpm v9+ lockfiles need **`pnpm.onlyBuiltDependencies`** in **`package.json`**).

**Verification**

```bash
bazel build //src/payment:payment_image //src/payment:payment_load --config=ci
bazel run //src/payment:payment_load
docker run --rm -e PAYMENT_PORT=50051 otel/demo-payment:bazel
```

**Next (BZ-122 / M4):** replicate for other services, align **`component-build-images.yml`**, registry push (**BZ-123**).

### 9.4 BZ-121 — Extension: **`frontend`** (Next.js)

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** for **`gcr.io/distroless/nodejs24-debian13:nonroot`** (multi-arch index digest pinned in **`MODULE.bazel`**), aligned with **`src/frontend/Dockerfile`**.  
2. **`src/frontend/BUILD.bazel`** — **`js_run_binary`** **`next_build`** produces **`.next`** (standalone + static). **`copy_to_directory`** **`frontend_image_root`** reshapes outputs to match the Docker layout (**`server.js`**, **`.next/static`**, **`public/`**, **`Instrumentation.js`**). **`mtree_spec`** / **`tar`** build **`frontend_image_layer`**; **`oci_image`** **`frontend_image`** uses **`entrypoint`** **`["/nodejs/bin/node"]`**, **`cmd`** **`["--require=./Instrumentation.js", "server.js"]`**, **`workdir`** **`/app`**, **`exposed_ports`** **`8080/tcp`**. **`oci_load`** **`frontend_load`** → **`otel/demo-frontend:bazel`**.  
3. **Build tags** — **`next_build`** and downstream image prep use **`tags = ["manual"]`** so **`bazel test //...`** does not accidentally pull the heavy graph; CI and docs call **`//src/frontend:frontend_image`** explicitly (see **§12**).

**Verification**

```bash
bazel build //src/frontend:frontend_image //src/frontend:frontend_load --config=ci
bazel run //src/frontend:frontend_load
docker image ls | grep otel/demo-frontend
```

### 9.5 BZ-121 — Extension: Python services (**`rules_pkg`** + **`py_binary`** runfiles)

**What we added**

1. **`MODULE.bazel`** — **`bazel_dep(rules_pkg, 1.0.1)`** and **`oci.pull`** for **`docker.io/library/python`** (**`python_312_slim_bookworm`**, multi-arch index digest **`sha256:31c0807da611e2e377a2e9b566ad4eb038ac5a5838cbbbe6f2262259b5dc77a0** — same tag as **`3.12-slim-bookworm`** from **`docker buildx imagetools inspect`**). **`use_repo`** exports **`python_312_slim_bookworm_{linux_amd64,linux_arm64}`**.

2. **`tools/bazel/py_oci.bzl`** — macro **`py_binary_oci`**: **`pkg_tar`** with **`include_runfiles = True`**, **`package_dir = "app"`**, then **`oci_image`** (**`base`** = **`@python_312_slim_bookworm_linux_amd64//:...`**), **`entrypoint`** = **`/app/<py_binary name>`**, **`workdir`** = **`/app`**, **`oci_load`** with **`otel/demo-*:bazel`** tags.

3. **Per-service `BUILD.bazel`** — **`recommendation`**, **`product_reviews`**, **`llm`**, **`load_generator`** each gain **`*_image`** / **`*_load`**. **Exposed ports** match **`.env`**: **9001**, **3551**, **8000**, **8089** (load-generator Locust web).

4. **Dockerfile parity** — gRPC Python Dockerfiles use **`opentelemetry-instrument`**; the **`py_binary`** already configures OTel in-process, so the Bazel image entrypoint is the stub only. **`load-generator`**: Bazel image does **not** run **`playwright install`**; Playwright-based users need the stock **`Dockerfile`** or an extra layer.

**Verification**

```bash
bazel build //src/recommendation:recommendation_image //src/product-reviews:product_reviews_image \
  //src/llm:llm_image //src/load-generator:load_generator_image --config=ci
bazel run //src/llm:llm_load
docker image ls | grep 'otel/demo-llm'
```

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

**Ongoing:** When adding **`py_test`**, **`rust_test`**, or **`js_test`** under M3+, apply the same tags (**`unit`** / **`manual`** / **`integration`** per **`docs/bazel/test-tags.md`**); Gazelle does not add tags automatically. The four Python services above have **no** in-tree tests yet, so no **`py_test`** targets were added.

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
bazel build //:smoke //pb:demo_proto //pb:go_grpc_protos //pb:demo_py_grpc --config=ci
bazel build //src/checkout/... //src/product-catalog/... //src/payment:payment --config=ci
bazel build //src/recommendation:recommendation //src/product-reviews:product_reviews //src/llm:llm //src/load-generator:load_generator --config=ci
bazel build //src/recommendation:recommendation_image //src/product-reviews:product_reviews_image //src/llm:llm_image //src/load-generator:load_generator_image --config=ci
bazel test  //src/checkout/... //src/product-catalog/... --config=ci
bazel test  //src/frontend:lint --config=ci   # BZ-051 (Next ESLint)
bazel test  //src/checkout/money:money_test --config=unit
bazel test  //... --config=unit   # all tests tagged `unit` (see docs/bazel/test-tags.md)
bazel build //src/checkout:checkout_image //src/checkout:checkout_load --config=ci   # BZ-121 (checkout)
bazel build //src/payment:payment_image //src/payment:payment_load --config=ci       # BZ-121 (payment)
bazel build //src/frontend:frontend_image //src/frontend:frontend_load --config=ci   # BZ-121 (frontend)
```

**Still to add (other M3 backlog items):**

```bash
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
