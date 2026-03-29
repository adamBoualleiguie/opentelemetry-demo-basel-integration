# M3 milestone — majority of application services in Bazel (alignment & conversion playbook)

This document is the **M3 milestone report** for `docs/planification/5-bazel-migration-task-backlog.md`. It does three things:

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
   - [6.2 `src/cart` (BZ-081)](#62-service-srccart-bz-081)  
7. [Epic J — Rust (BZ-090)](#7-epic-j--rust-bz-090)  
   - [7.2 `src/currency` — C++ / gRPC (BZ-092)](#72-service-srccurrency--c--grpc-bz-092)  
   - [7.3 `src/email` — Ruby (BZ-093)](#73-service-srcemail--ruby-bz-093)  
   - [7.4 `src/flagd-ui` — Elixir / Phoenix (BZ-094)](#74-service-srcflagd-ui--elixir--phoenix-bz-094)  
   - [7.5 `src/quote` — PHP (BZ-095)](#75-service-srcquote--php-bz-095)  
   - [7.6 `src/react-native-app` — Expo / React Native, Android only (BZ-096)](#76-service-srcreact-native-app--expo--react-native-android-only-bz-096)  
   - [7.7 `src/frontend-proxy` / `src/image-provider` — Envoy / nginx (BZ-097)](#77-srcfrontend-proxy--srcimage-provider--envoy--nginx-bz-097)  
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
| **I** | **BZ-081** | `cart` + tests | **M4** (tests) / **this fork** (build + OCI) | **M4:** **`//src/cart:cart_dotnet_test`** (**`sh_test`** + host **`dotnet test`**). **This fork:** **`cart_publish`** + **`cart_image`** (**§6.2**, **§9.9**) — same **`dotnet_publish`** rule as **`accounting`**, nested tree + **`pb/demo.proto`**. |
| **J** | **BZ-090** | `shipping` — Rust | M3 | `rust_library` / `rust_binary`, tests; Cargo.toml integration; proto if applicable. `bazel build` + `bazel test` for shipping. |
| **F** | **BZ-051** | `frontend` — Next.js | M3 | Build and lint under Bazel; document Next.js + Bazel caveats. |
| **M** | **BZ-120** | Choose OCI rule stack + base policy | M3 | ADR or doc; one pilot image (**BZ-121**). |
| **M** | **BZ-121** | Pilot image (`checkout` or `payment`) | M3 | `docker load` or registry push dry-run documented. |
| **M** | **BZ-122** | Roll out images per service | **M4** | Not M3. |
| **N** | **BZ-130** | Global test tag convention | M3 | Documented; `.bazelrc` examples for filters. Depends on **BZ-013**. |
| **N** | **BZ-131**–**133** | Cypress, Tracetest, consolidate unit tests | M4–M5 | Out of M3 strict scope; noted for sequencing. |
| **—** | **BZ-095** | `quote` — PHP / Composer | M3 (this fork) | **`composer_install`** + **`sh_test`** smoke + **`oci_image`** on **`php:8.4-cli-alpine3.22`**; documented in **§7.5** / **§9.13** (not a separate line in upstream backlog — local ID aligned after **BZ-094**). |
| **—** | **BZ-096** | `react-native-app` — Android (Expo) | M3 (this fork) | Hermetic **`@rn_android_sdk`** (Temurin 17 + **sdkmanager**); **`sh_test` `rn_js_checks`** (**`tsc`** + **`jest`**); **`manual`** **`android_debug_apk`** (**Gradle** **`assembleDebug`**). **iOS not in Bazel.** See **§7.6**. |
| **—** | **BZ-097** | `frontend-proxy` (Envoy), `image-provider` (nginx) | M3 (this fork) | **`genrule`** + host **`envsubst`** bake templates to fixed configs; **`oci_image`** on digest-pinned **Envoy** / **nginx-unprivileged-otel**; **`sh_test`** config smoke (**`unit`**, **`no-sandbox`**). See **§7.7** / **§9.14** (not a separate upstream backlog line — local ID after **BZ-096**). |

**Proto dependencies called out by backlog:** **BZ-032** (Python grpc), **BZ-034** (Java/Kotlin), **BZ-036** (.NET) — these tie M3 services to the central `pb/demo.proto` story from M1 (`docs/bazel/proto-policy.md`).

---

## 2. High-level status in this fork

| Area | Backlog | In-repo today |
|------|---------|----------------|
| Go `checkout`, `product-catalog` | M2 (BZ-040/041) | **Built & tested** under Bazel (M2). M3 uses them for **BZ-121** pilot candidate. |
| Node `payment` | M2 (BZ-050) | **`js_binary`** (M2) + **BZ-121** **`payment_image`** / **`payment_load`** (see §9.3). |
| Python ×4 | M3 (BZ-060/061) + **BZ-121** OCI | **Buildable:** `rules_python` + dual **`pip.parse`** hubs; **`//pb:demo_py_grpc`**; **`py_binary`** + **`oci_image`** / **`oci_load`** per service (**§4**, **§9.5**). |
| Java `ad`, Kotlin `fraud-detection` | M3 (BZ-070/071) + **BZ-034** + **BZ-121** | **Built in Bazel:** `//src/ad:ad`, `//src/fraud-detection:fraud_detection`; protos from **`//pb:demo_java_grpc`**; **`oci_image`** / **`oci_load`** **`ad_oci_*`**, **`fraud_detection_oci_*`** (see **§5**, **§9.6**). Gradle/Docker remain alternate entrypoints. **No `java_test` / `kt_jvm_test`** in-tree yet. |
| .NET `accounting` | M3 (BZ-080 + BZ-121 OCI) | **`dotnet_publish`** → **`//src/accounting:accounting_publish`**; **`pkg_tar`** + **`oci_image`** **`accounting_image`** / **`oci_load`** (**`otel/demo-accounting:bazel`**) on **`dotnet_aspnet_10`**. Host **.NET 10**; **`requires-network`**. |
| .NET `cart` | BZ-081 + **BZ-121** + **M4** tests | **`//src/cart:cart_publish`**, **`cart_image`** / **`cart_load`** (**`otel/demo-cart:bazel`**). **`//src/cart:cart_dotnet_test`** — xUnit via **`dotnet test`** (**`unit`**, **`requires-network`**, **`no-sandbox`**). See **`docs/bazel/milestones/m4-completion.md`**. |
| Rust `shipping` | M3 (BZ-090 + **BZ-121** OCI) | **`rules_rust` 0.69** + **`crate_universe`** **`shipping_crates`**; **`rust_library`** / **`rust_binary`** / **`rust_test`** (**`unit`**). **OCI:** **`shipping_image`** / **`shipping_load`** → **`otel/demo-shipping:bazel`** on **`gcr.io/distroless/cc-debian13:nonroot`** (**`distroless_cc_debian13_nonroot`** in **`MODULE.bazel`**); **`mtree_spec`** / **`tar`** layer places **`shipping`** at **`/app/shipping`** (same as **`src/shipping/Dockerfile`**). **Proto:** not in Bazel yet (**`docs/bazel/proto-policy.md`**). Repin: **`CARGO_BAZEL_REPIN=1 bazel sync --only=shipping_crates`**. |
| C++ `currency` | M3 (**BZ-092** + **BZ-121** OCI) | **`grpc` 1.66.0.bcr.2** + **`opentelemetry-cpp` 1.24.0.bcr.1** + **`googletest`** in **`MODULE.bazel`**; **`single_version_override`** on **`protobuf`**, **`grpc`**, and **`abseil-cpp`** so C++ gRPC + protobuf 29.x stay consistent (avoids Bzlmod pulling protobuf 33 / grpc 1.69, which breaks the gRPC C++ / protobuf **upb** graph). **`//pb:demo_cpp_grpc`** (**`cc_proto_library`** + **`cc_grpc_library`**) for optional reuse; **`//src/currency`** copies **`//pb:demo.proto`** via **`genrule`** (protobuf requires same-package **`.proto`**), then **`cc_grpc_library`** (**`grpc_only`**) + **`cc_proto_library`**. **`currency_includes.bzl`** rule adds **`-I`** for **`bazel-bin/src/currency`** and **`bazel-bin/external/grpc~/src/proto`** so **`#include <demo.grpc.pb.h>`** and **`#include <grpc/health/v1/health.grpc.pb.h>`** resolve (gRPC health stubs from **`@com_github_grpc_grpc//src/proto/grpc/health/v1:health_proto`** — not **`@grpc-proto`**, because **`cc_grpc_library` cannot codegen from an external-repo path referenced only from `//pb`**). **`cc_library` `currency_lib`** uses **`features = ["-pic"]`** so gRPC stub code links as **`.a`** (avoids **`libcurrency_*_cc_grpc.so`** undefined **C core** symbols at link time). **`cc_binary` `currency`**; **`cc_test` `currency_proto_smoke_test`** (**`unit`**) links **`cc_proto`** only. **OCI:** **`currency_image`** / **`currency_load`** → **`otel/demo-currency:bazel`** on **`distroless_cc_debian13_nonroot`** (**`7001/tcp`**, **`cmd = ["7001"]`**, **`entrypoint = ["./currency"]`**). |
| Ruby `email` | M3 (**BZ-093** + **BZ-121** OCI) | **`rules_ruby` 0.24** — portable MRI **3.4.8** (**`version_file = "//src/email:.ruby-version"`**), **`ruby.bundle_fetch`** **`email_bundle`** from **`Gemfile` / `Gemfile.lock`**. **`rb_library` / `rb_binary` `email`**; **`rb_test` `email_gems_smoke_test`** (**`unit`**). **`Gemfile.lock`** **`PLATFORMS`** limited to **`x86_64-linux`** + **`aarch64-linux`** (glibc) so **`bundle install`** under Bazel resolves **grpc** / native gems for Linux; **`google-protobuf`** uses **`force_ruby_platform: true`**. **OCI:** **`email_image`** / **`email_load`** → **`otel/demo-email:bazel`** on **`docker.io/library/ruby:3.4.8-slim-bookworm`** (**`ruby_348_slim_bookworm`** in **`MODULE.bazel`** — Debian **glibc**, distinct from Compose **Alpine** Dockerfile). |
| Elixir `flagd-ui` | M3 (**BZ-094** + **BZ-121** OCI) | **`mix_release`** (**`//tools/bazel:mix_release.bzl`**) → **`//src/flagd-ui:flagd_ui_publish`** (host **`mix release`**, **`requires-network`**). **`sh_test` `flagd_ui_mix_test`** (**`mix test`**, **`unit`**, **`requires-network`**, **`size = "enormous"`**). **OCI:** **`flagd_ui_image`** / **`flagd_ui_load`** → **`otel/demo-flagd-ui:bazel`** on **`debian:bullseye-20251117-slim`** (**`debian_bullseye_20251117_slim`**). **CI:** **`erlef/setup-beam`** (**Elixir 1.19.3**, **OTP 28.0.2**) + **`build-essential`** / **`git`**. |
| PHP `quote` | M3 (**BZ-095** + **BZ-121** OCI) | **`composer_install`** (**`//tools/bazel:composer_install.bzl`**) → **`//src/quote:quote_publish`** (host **`composer install`**, **`requires-network`** — no **`composer.lock`**; mirrors **Dockerfile** vendor flags). **`sh_test` `quote_composer_smoke_test`** (**`unit`**, **`requires-network`**, **`size = "enormous"`** — **`vendor/autoload.php`** smoke). **OCI:** **`quote_image`** / **`quote_load`** → **`otel/demo-quote:bazel`** on **`php:8.4-cli-alpine3.22`** (**`php_84_cli_alpine322`**). **CI:** **`shivammathur/setup-php`** (**PHP 8.4** + **Composer**). **Caveat:** **Dockerfile** installs **PECL** extensions (**`opentelemetry`**, **`protobuf`**, …); Bazel base is stock **CLI** image — see **`oci-policy.md`**. |
| Expo **`react-native-app`** | M3 (**BZ-096**, **Android only**) | **Hermetic** **`@rn_android_sdk`** (**`tools/bazel/rn_android/sdk_repo.bzl`**) — **Temurin 17** + **cmdline-tools** + **`sdkmanager`** (**API 34**, **build-tools 34.0.0**, **NDK 26.1.10909125**); **linux-amd64** only. **`sh_test` `rn_js_checks`**: **`npm ci`**, **`tsc --noEmit`**, **`jest --ci --passWithNoTests`** (**`unit`**, **`requires-network`**). **`rn_android_debug_apk` `android_debug_apk`**: **`npm ci`** + **`./gradlew :app:assembleDebug`** (**`manual`**, **`no-sandbox`**, **`requires-network`**). **JDK for Gradle** inside the APK action comes from **`@rn_android_sdk`**, **not** SDKMAN / **`~/.sdkman`**. **No** **`rules_js`** hub for this app (lockfile stays **`npm`**). **No iOS** targets. **No container image** (mobile APK artifact). |
| Envoy **`frontend-proxy`** | M3 (**BZ-097**) | **`genrule` `envoy_compose_defaults_yaml`** (**`bake_envoy.sh`**, **`envsubst`** on **`envoy.tmpl.yaml`**) → **`pkg_tar`** **`/etc/envoy/envoy.yaml`**; **`oci_image` `frontend_proxy_image`** / **`oci_load` `frontend_proxy_load`** → **`otel/demo-frontend-proxy:bazel`** (**`envoy_v134_latest`**). **`sh_test` `frontend_proxy_config_test`** (**`unit`**, **`no-sandbox`**). Host needs **`gettext-base`** for **`genrule`** / tests. |
| nginx **`image-provider`** | M3 (**BZ-097**) | **`genrule` `nginx_compose_defaults_conf`** (**`bake_nginx.sh`**) → **`pkg_tar`** **`/etc/nginx/nginx.conf`** + static assets under **`/static`**; **`oci_image` `image_provider_image`** (**`user = "101"`**) / **`image_provider_load`** → **`otel/demo-image-provider:bazel`** (**`nginx_unprivileged_1290_alpine322_otel`**). **`sh_test` `image_provider_config_test`** (**`unit`**, **`no-sandbox`**). |
| Next `frontend` | M3 (BZ-051) | **`next build`** via **`js_run_binary`** **`//src/frontend:next_build`**; **lint** **`//src/frontend:lint`**; **`npm_frontend`** + `pnpm-lock.yaml` (see [§8](#8-epic-f--node-frontend-bz-051)). |
| OCI policy | M3 (BZ-120) | **Documented** in `docs/bazel/oci-policy.md` (**rules_oci** direction, pilot scope). |
| Pilot OCI image | M3 (BZ-121 + **BZ-097**) | **Implemented** for **`checkout`**, **`payment`**, **`frontend`**, the **four Python** services, **JVM `ad` / `fraud-detection`**, **.NET `accounting`**, **.NET `cart`**, **Rust `shipping`**, **C++ `currency`**, **Ruby `email`**, **Elixir `flagd-ui`**, **PHP `quote`**, **Envoy `frontend-proxy`**, and **nginx `image-provider`**: **`oci_image`** + **`oci_load`** (see [§9](#9-epic-m--oci-images-bz-120-bz-121), **§9.14**). Bases are digest-pinned in **`MODULE.bazel`**; **Go** uses **distroless static**; **Rust** and **C++ (glibc-linked)** use **distroless cc**; JVM uses **distroless Java 21 / 17** + deploy JAR layers; **.NET** services use **aspnet 10.0** under **`/app`**; **Ruby `email`** uses **`ruby:3.4.8-slim-bookworm`**; **Elixir `flagd-ui`** uses **`debian:bullseye-slim`** + **`mix release`** tarball; **PHP `quote`** uses **`php:8.4-cli-alpine3.22`** + **`composer install`** tree under **`/var/www`**; **BZ-097** uses **upstream Envoy** and **nginxinc/nginx-unprivileged** **`-otel`** with **baked** configs (**§7.7**). |
| Test tags | M3 (BZ-130) | **Done**: `.bazelrc` configs; all **`go_test`** targets tagged; **`//src/shipping:shipping_test`**, **`//src/currency:currency_proto_smoke_test`**, **`//src/email:email_gems_smoke_test`**, **`//src/flagd-ui:flagd_ui_mix_test`**, **`//src/quote:quote_composer_smoke_test`**, **`//src/react-native-app:rn_js_checks`**, **`//src/frontend-proxy:frontend_proxy_config_test`**, **`//src/image-provider:image_provider_config_test`** tagged **`unit`**; **`docs/bazel/test-tags.md`**; **CONTRIBUTING** pointer. |

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

### 5.0 Cross-cutting: **BZ-034** (Java / Kotlin proto + gRPC) and Maven strategy

**Goal:** One canonical Java API for `pb/demo.proto` (messages + gRPC stubs) that both JVM services depend on, aligned with **`docs/bazel/proto-policy.md`**.

**Implemented in `pb/BUILD.bazel`:**

- **`java_proto_library`** **`demo_java_proto`** on **`demo_proto`**.  
- **`java_grpc_library`** from **`@grpc-java//:java_grpc_library.bzl`** (**`demo_java_grpc_internal`**) with **`srcs = [":demo_proto"]`**, **`deps = [":demo_java_proto"]`**.  
- **`demo_java_grpc`** — thin **`java_library`** that **`exports`** proto + gRPC internal jars so consumers add a single **`//pb:demo_java_grpc`** dep.  
- **`java_grpc_protos`** **`filegroup`** — optional CI grouping (**`bazel build //pb:java_grpc_protos`** builds the same graph as **`demo_java_grpc`** via **`data`**).

**Tooling notes:**

- Root **`MODULE.bazel`** declares **`bazel_dep(grpc-java, 1.78.0)`** so **`java_grpc_library`** and **`@grpc-java//...`** Java targets resolve from the same stack as codegen.  
- **`bazel_dep(grpc-proto, 0.0.0-20240627-ec30f58)`** matches grpc-java’s grpc-proto pin so **`@grpc-proto//:health_java_proto`** is visible for **strict Java deps** (see **§5.1**): **`ad`** references **`io.grpc.health.v1.HealthCheckResponse.ServingStatus`**, which must not be “indirect only” under **`--strict_java_deps`**.  
- **Host C++ for gRPC Java codegen:** `.bazelrc` sets **`common --host_cxxopt=-std=c++17`** and **`common --cxxopt=-std=c++17`** so Abseil / protobuf C++ toolchains used while building the Java plugin meet **C++17** (otherwise analysis fails on older defaults).

**Maven pin strategy (`rules_jvm_external`):**

- Single **`maven.install(name = "maven", …)`** in the root module with **`known_contributing_modules = ["grpc-java", "otel_demo", "protobuf"]`** so grpc-java’s Maven graph and the app’s coordinates merge without a second **`use_repo`** hub.  
- Application JARs are listed explicitly in **`artifacts = [...]`** (OpenTelemetry **1.60.1** line, FlagD, Log4j, Jackson, Kafka, **`protobuf-kotlin`**, **`javax.annotation-api`**, etc.) — **pin in one place**; refresh with **`bazel run @rules_jvm_external//:pin`** when bumping versions (see rules_jvm_external docs).  
- **`use_repo(maven, "maven")`** exposes **`@maven//:io_opentelemetry_*`**, **`@maven//:com_google_guava_guava`**, etc.

**Rules wiring:**

- **`bazel_dep(rules_java, 8.5.1)`** — explicit (same major line as grpc-java); **`rules_jvm_external` 6.9**; **`rules_kotlin` 2.3.20** with **`rules_kotlin_extensions`** + **`register_toolchains("@rules_kotlin//kotlin/internal:default_toolchain")`**.

---

### 5.1 Service: `src/ad` (Java) — **BZ-070**

| Field | Detail |
|-------|--------|
| **Stack** | **Gradle** remains valid locally; **Bazel** mirrors **`src/main/java`** + **`src/main/resources`**. |
| **Build today** | Docker / `./gradlew`; Bazel: **`java_binary`** **`//src/ad:ad`**, **`main_class = "oteldemo.AdService"`**. |
| **Proto** | **`//pb:demo_java_grpc`**. |
| **Runtime** | **`@grpc-java//api`**, **`core_maven`**, **`netty`**, **`protobuf`**, **`stub`**, **`services:services_maven`**; **`@grpc-proto//:health_java_proto`** (strict deps); **`@maven//`** for Guava, OTel (incl. **`opentelemetry-context`**), instrumentation annotations, FlagD, Log4j, **`javax.annotation-api`**; Jackson on **`java_binary`** **`runtime_deps`**. |

**Targets (`src/ad/BUILD.bazel`):**

| Target | Role |
|--------|------|
| **`ad_lib`** | **`java_library`** — **`srcs = glob(["src/main/java/**/*.java"])`**, **`resources = glob(["src/main/resources/**"])`**. |
| **`ad`** | **`java_binary`** — runnable wrapper + **`runtime_deps`** for Jackson. |
| **`ad_oci_image` / `ad_oci_load`** | **`java_deploy_jar_oci`** (**`//tools/bazel:java_oci.bzl`**): **`pkg_tar`** of **`ad_deploy.jar`** + **`oci_image`** on **`distroless_java21_debian12_nonroot`** (**linux/amd64**); **`otel/demo-ad:bazel`**. |

**Fat JAR / Docker parity:** build **`//src/ad:ad_deploy.jar`** for a single classpath-merged artifact (Gradle **installDist** / image stages can consume this path under **`bazel-bin`**). The **OCI** target reuses that deploy JAR (see **`ad_oci_*`** above).

**Escape hatch:** no **`genrule` + `./gradlew`** was required; if a future dependency blocks Bazel, the backlog-allowed genrule path remains documented in the task matrix (**§1**).

**Tests:** no **`src/test`** Java tree in this demo service — no **`java_test`** added.

**Status in this repository:** **Implemented** (build + **`ad_oci_image`** + CI smoke). **Docker / compose parity:** Bazel images omit the **OTel Java agent** bundle that **`src/ad/Dockerfile`** downloads; set **`JAVA_TOOL_OPTIONS`** or add a layer if you need identical instrumentation.

---

### 5.2 Service: `src/fraud-detection` (Kotlin) — **BZ-071**

| Field | Detail |
|-------|--------|
| **Stack** | Kotlin JVM; **Gradle shadow** remains the upstream pattern; Bazel uses **`rules_kotlin`** + **`java_binary`**. |
| **Proto** | Kotlin consumes the same generated **Java** stubs: **`//pb:demo_java_grpc`** (no separate Kotlin protoc plugin for this service — **`protobuf-kotlin`** on the classpath for runtime where needed). |
| **Runtime** | **`@maven//`** Kafka clients, OTel API/SDK + extension annotations, FlagD, Log4j, slf4j, **`com_google_protobuf_protobuf_kotlin`**, **`javax.annotation_api`**. |

**Targets (`src/fraud-detection/BUILD.bazel`):**

| Target | Role |
|--------|------|
| **`fraud_detection_lib`** | **`kt_jvm_library`** — **`src/main/kotlin/**/*.kt`**, resources glob. |
| **`fraud_detection`** | **`java_binary`**, **`main_class = "frauddetection.MainKt"`**, **`runtime_deps = [":fraud_detection_lib"]`**. |
| **`fraud_detection_oci_image` / `fraud_detection_oci_load`** | Same macro as **`ad`**, base **Java 17** distroless (Kafka worker; **no** **`exposed_ports`**). **`otel/demo-fraud-detection:bazel`**. |

**Shadow JAR equivalent:** **`//src/fraud-detection:fraud_detection_deploy.jar`** — same semantics as **`ad_deploy.jar`** (one self-contained JAR for OCI or **`java -jar`**). This matches the **fat / shadow** intent for the Kafka worker without duplicating Gradle’s **`shadowJar`** task in Bazel.

**Status in this repository:** **Implemented** (build + **`fraud_detection_oci_image`** + CI smoke). Same **OTel agent** caveat as **`ad`** (**`src/fraud-detection/Dockerfile`** uses **`-javaagent`**).

---

### 5.3 Verification (Epic H)

```bash
bazel build //pb:demo_java_grpc //pb:java_grpc_protos --config=ci
bazel build //src/ad:ad //src/fraud-detection:fraud_detection --config=ci
# Optional — fat JARs (BZ-071 shadow parity / image prep):
bazel build //src/ad:ad_deploy.jar //src/fraud-detection:fraud_detection_deploy.jar --config=ci
# OCI / docker load (BZ-121):
bazel build //src/ad:ad_oci_image //src/fraud-detection:fraud_detection_oci_image --config=ci
bazel run //src/ad:ad_oci_load
bazel run //src/fraud-detection:fraud_detection_oci_load
docker image ls | grep -E 'otel/demo-ad:bazel|otel/demo-fraud-detection:bazel'
```

---

## 6. Epic I — .NET (BZ-080)

### 6.1 Service: `src/accounting`

| Field | Detail |
|-------|--------|
| **Stack** | **.NET 10** (`Accounting.csproj`, **`net10.0`**), Kafka + EF Core + **Google.Protobuf** + **Grpc.Tools** (`GrpcServices="none"` — messages only). |
| **Build today** | Docker **`dotnet publish`**; local **`dotnet`** when developing. |
| **Proto (BZ-036 / `proto-policy.md`)** | Canonical file is **`pb/demo.proto`**. **`Accounting.csproj`** expects **`src/protos/demo.proto`** (Docker **`COPY`** from **`/pb/demo.proto`**). Bazel does **not** commit that path (it is **`.gitignore`d**); the **`dotnet_publish`** rule **copies `//pb:demo.proto`** into a temp tree as **`src/protos/demo.proto`** before **`dotnet restore` / `dotnet publish`**, matching Dockerfile layout and single-source proto policy. C# codegen still runs via **MSBuild `Protobuf` items** + **Grpc.Tools** (same as **`dotnet build`** outside Bazel). |
| **Backlog** | **BZ-080** — `rules_dotnet` **or** wrapper with explicit outputs. |

**What we implemented (wrapper / Starlark rule, not `rules_dotnet`)**

1. **`//tools/bazel:dotnet_publish.bzl`** — rule **`dotnet_publish`**: writes a **manifest** of **`(input path, dest relative to package)`** lines (flat **`accounting`** → basenames only; nested **`cart`** → preserves **`src/...`**, **`Directory.Build.props`**, etc.), copies into **`$$(mktemp -d)`**, adds **`proto`** at **`proto_dest`** (default **`src/protos/demo.proto`**; **`cart`** uses **`pb/demo.proto`**), then **`dotnet restore`** / **`dotnet publish`** with optional **`extra_publish_args`**. Declares a **`directory` output**. **`use_default_shell_env = True`**; **`requires-network`** for NuGet.  
2. **`src/accounting/BUILD.bazel`** — **`filegroup`** **`accounting_sources`** + **`dotnet_publish`** **`accounting_publish`** (**`proto = "//pb:demo.proto"`**); **`rules_pkg`** **`pkg_tar`** **`accounting_layer`** (**`package_dir = "app"`**) over **`accounting_publish`**; **`oci_image`** **`accounting_image`** (**`base`** = **`@dotnet_aspnet_10_linux_amd64//:dotnet_aspnet_10_linux_amd64`**, **`workdir`** **`/app`**, **`entrypoint`** **`["./instrument.sh", "dotnet", "Accounting.dll"]`**, OTel **`env`**); **`oci_load`** **`accounting_load`** → **`otel/demo-accounting:bazel`**.  
3. **Hermeticity trade-off:** the rule uses the **host (or CI) .NET SDK** — same class of assumption as many **`genrule`/`run_binary`** migrations. A future **`rules_dotnet`** + pinned SDK could replace this when **`net10`** support and repo policy align.  
4. **Tests:** no **`*.Tests.csproj`** for **`accounting`** — no **`bazel test`** there. **`cart`:** **`//src/cart:cart_dotnet_test`** (**M4** / **BZ-081**).

**Prerequisites**

- **SDK:** **.NET 10** (matches **`TargetFramework` = `net10.0`**). **.NET SDK 8.x fails** with **`NETSDK1045`** (“does not support targeting .NET 10.0”). CI: **`actions/setup-dotnet@v4`** with **`dotnet-version: '10.0.x'`** in **`bazel_smoke`**.  
- **Sandbox / SDK discovery:** **`dotnet_publish`** prefers **`DOTNET_ROOT`**, then **`~/.dotnet`** (real user home via **`getent passwd`** when Bazel uses a temp **`HOME`**), then **`/usr/share/dotnet`**, and only uses a root if **`dotnet --version`** is **10.***. **`.bazelrc`** sets **`--action_env=PATH`** and **`--action_env=DOTNET_ROOT`** so CI’s **`setup-dotnet`** layout is visible inside actions. The rule still sets **`HOME`** / **`DOTNET_CLI_HOME`** under a temp dir for **NuGet** after the SDK is on **`PATH`**.  
- **Network:** first **`dotnet restore`** per machine/CI needs NuGet access (**`requires-network`** on the target).

**Verification**

```bash
bazel build //src/accounting:accounting_publish //src/accounting:accounting_image //src/accounting:accounting_load --config=ci
# Inspect publish outputs (paths vary by config):
# ls $(bazel info bazel-bin)/src/accounting/accounting_publish
# Optional: load into Docker
# bazel run //src/accounting:accounting_load
# docker image ls | grep otel/demo-accounting
```

**Status in this repository:** **Implemented** — **`accounting_publish`** (CI smoke) plus **BZ-121-style** **`accounting_image`** / **`accounting_load`**. The stock **`src/accounting/Dockerfile`** creates **`/var/log/opentelemetry/dotnet`** and **`chown`** for **`app`**; the Bazel image does **not** add that directory yet — add a small **`pkg_tar`** if you need identical filesystem parity.

### 6.2 Service: src/cart (BZ-081)

| Field | Detail |
|-------|--------|
| **Stack** | **.NET 10** **`src/cart.csproj`** (**ASP.NET Core** gRPC, **Valkey**, **OpenTelemetry** NuGet packages, **OpenFeature** / **flagd**). |
| **Build today** | Docker multi-stage **`linux-musl`** **single-file** **`./cart`** on **`runtime-deps:alpine`** (**`src/cart/src/Dockerfile`**). |
| **Proto** | **`cart.csproj`** uses **`Protobuf` Include="$(ProtosDir)\**\*.proto"`** with **`ProtosDir`** resolving to repo **`pb/`** (same canonical **`demo.proto`** as **`//pb:demo.proto`**). |
| **Backlog** | **BZ-081** — **`bazel test //src/cart:cart_dotnet_test`** (**M4**; **`run_cart_dotnet_test.sh`**). |

**Why this is separate from §6.1:** **`cart`** is a **nested** tree (**`src/*.cs`**, **`cart.slnx`**, **`tests/`** excluded from publish **`filegroup`**). The shared **`dotnet_publish`** rule was extended so each source file’s destination under the temp root is **path relative to the Bazel package** (`src/cart/…`), not **`basename` only** (which would collide for multiple **`.cs`** files). **`proto_dest = "pb/demo.proto"`** matches the **`../pb`** layout next to the **`src/`** project directory inside **`src/cart/`**.

**Dockerfile vs Bazel image**

| Topic | Docker (`src/cart/src/Dockerfile`) | Bazel (`cart_image`) |
|--------|-------------------------------------|----------------------|
| **Output** | **Self-contained** single native binary **`cart`** | **Framework-dependent** **`cart.dll`** + **`dotnet`** host |
| **Base** | **`mcr.microsoft.com/dotnet/runtime-deps:10.0-alpine3.22`** | **`mcr.microsoft.com/dotnet/aspnet:10.0`** (**`dotnet_aspnet_10`**, digest-pinned) |
| **Entrypoint** | **`./cart`** | **`dotnet cart.dll`** |
| **Rationale** | Upstream chosen musl + single-file | Reuse same **aspnet** OCI story as **`accounting`**; avoid RID / cross-RID complexity in the generic **`dotnet_publish`** action. |

**Publish flags in Bazel:** **`extra_publish_args = "/p:PublishSingleFile=false /p:SelfContained=false"`** so **`dotnet publish`** overrides the **`.csproj`** **`<PublishSingleFile>true`**, **`<SelfContained>true`**, producing an **FDD** layout suitable for **`aspnet`**.

**`src/cart/BUILD.bazel`**

1. **`cart_publish_sources`** — **`glob`** over **`src/**/*.cs`**, **`src/**/*.csproj`**, **`src/**/*.json`**, **`Directory.Build.props`**, **`NuGet.config`**, **`cart.slnx`**; excludes **`src/bin/**`**, **`src/obj/**`**; **does not** include **`tests/`** (test project is not part of the shipping binary graph).  
2. **`dotnet_publish`** **`cart_publish`** — **`csproj = "src/cart.csproj"`**, **`proto_dest = "pb/demo.proto"`**, **`requires-network`**.  
3. **`pkg_tar`** **`cart_layer`** + **`oci_image`** **`cart_image`** — **`workdir`** **`/app`**, **`entrypoint`** **`["dotnet", "cart.dll"]`**, **`7070/tcp`** (**.env** **`CART_PORT`**). **`oci_load`** **`cart_load`** → **`otel/demo-cart:bazel`**.  
4. **Runtime:** container still needs **`VALKEY_ADDR`** (and usual OTel env vars) like Docker Compose.

**Verification**

```bash
bazel build //src/cart:cart_publish //src/cart:cart_image //src/cart:cart_load --config=ci
# dotnet test (not in Bazel yet):
# (from repo root) dotnet test src/cart/tests/cart.tests.csproj
```

**Status in this repository:** **`cart_publish`** + **`cart_image`** / **`cart_load`** + **`cart_dotnet_test`** **implemented** (**BZ-081** tests in **M4**).

---

## 7. Epic J — Rust (BZ-090)

### 7.1 Service: `src/shipping`

| Field | Detail |
|-------|--------|
| **Stack** | **Cargo** (`Cargo.toml`, **`edition = "2021"`**), **actix-web**, **tonic** (errors + OTLP), OpenTelemetry crates. |
| **Build today** | `cargo build` / **`cargo test`** locally; Docker **`cargo build --release`**. |
| **Proto** | Service does **not** import **`demo.proto`** types today. When it should: add **`rust_proto_library`** / **prost** from **`//pb:demo_proto`** (or a **`cargo_build_script`** bridge) per **`docs/bazel/proto-policy.md`**. |
| **Backlog** | **BZ-090** — **`rust_binary`** + **`rust_test`**, Cargo lockfile + crate universe. |

**What we implemented**

1. **`MODULE.bazel`** — **`bazel_dep(rules_rust, 0.69.0)`**; **`rust.toolchain(edition = "2021")`** + **`register_toolchains("@rust_toolchains//:all")`**. **Do not** declare a second **`rust_host_tools`** tag in the root module (**rules_rust** already registers it — duplicate **`host_tools`** breaks analysis).  
2. **`crate_universe`** — extension **`shipping_crate_index`**, **`from_cargo`** **`name = "shipping_crates"`** with **`cargo_lockfile = "//src/shipping:Cargo.lock"`**, **`manifests = ["//src/shipping:Cargo.toml"]`**, **`lockfile = "//src/shipping:cargo-bazel-lock.json"`** (committed for reproducible CI). After changing **`Cargo.toml`** / **`Cargo.lock`**, run **`CARGO_BAZEL_REPIN=1 bazel sync --only=shipping_crates`** (or **`REPIN=1`**) and commit the updated **`cargo-bazel-lock.json`**.  
3. **`src/shipping/BUILD.bazel`** — **`load("@shipping_crates//:defs.bzl", "aliases", "all_crate_deps")`**; **`rust_library`** **`shipping_lib`** with **`crate_name = "shipping"`** (so **`main.rs`** can **`use shipping::...`**), **`rust_binary`** **`shipping`** (**`deps = [":shipping_lib"] + all_crate_deps(normal = True)`** + proc-macros for **`#[actix_web::main]`**), **`rust_test`** **`shipping_test`** **`crate = ":shipping_lib"`** with **`tags = ["unit"]`**.  
4. **`src/lib.rs`** — **`pub mod telemetry_conf`**, **`pub mod shipping_service`**, re-exports **`get_quote`** / **`ship_order`** so the crate matches Cargo’s library + binary layout.  
5. **Tests:** **`quote`** module **`#[test]`**s and **`shipping_service`** **`#[actix_web::test]`** run via **`rust_test`** on **`shipping_lib`**. **`ShipOrderRequest`** in tests uses **`address: None`**, **`items: vec![]`** (structural init; **`ShipOrderRequest {}`** is invalid without **`Default`**).  
6. **BZ-121 OCI** — **`MODULE.bazel`** **`oci.pull`** **`distroless_cc_debian13_nonroot`** (index digest **`sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e`**, **`gcr.io/distroless/cc-debian13`**) matches **`src/shipping/Dockerfile`** runtime (**not** **`static`** — default **`rules_rust`** Linux GNU target links **glibc**). **`src/shipping/BUILD.bazel`**: **`mtree_spec`** / **`mtree_mutate`** (**`package_dir = "app"`**) / **`tar`** **`shipping_layer`**, **`oci_image`** **`shipping_image`** (**`entrypoint`** **`["./shipping"]`**, **`workdir`** **`/app`**, **`50050/tcp`**), **`oci_load`** **`shipping_load`** → **`otel/demo-shipping:bazel`**.

**Verification**

```bash
bazel build //src/shipping:shipping //src/shipping:shipping_lib --config=ci
bazel build //src/shipping:shipping_image //src/shipping:shipping_load --config=ci
bazel test //src/shipping/... --config=ci
bazel test //src/shipping:shipping_test --config=unit
# optional: bazel run //src/shipping:shipping_load && docker image ls | grep otel/demo-shipping
```

**Status in this repository:** **Implemented** (**BZ-090** build/test + **BZ-121** **`shipping_image`** / **`shipping_load`**). **Fully static** Rust (**musl**) could switch the base to **`distroless_static`** later; not attempted here.

---

### 7.2 Service: `src/currency` — C++ / gRPC (BZ-092)

| Field | Detail |
|-------|--------|
| **Stack** | **C++17**, **gRPC** + **Protobuf**, **opentelemetry-cpp** OTLP gRPC exporters (trace, metrics, logs) via **`tracer_common.h`**, **`meter_common.h`**, **`logger_common.h`**. |
| **Build today** | Docker **Alpine** + **CMake** (see **`src/currency/Dockerfile`**); committed **`build/generated/proto`** is **not** the Bazel source of truth. |
| **Proto (BZ-035 / `proto-policy.md`)** | Canonical file remains **`pb/demo.proto`**. **`proto_library`** in **`//src/currency`** must see **`.proto` files in the same package**, so a **`genrule`** copies **`//pb:demo.proto`** → **`demo.proto`** under the package. Optional **`//pb:demo_cpp_grpc`** builds the same API for other C++ packages (consumers outside **`//src/currency`** would need their own include strategy or local codegen). |
| **Health** | **`#include <grpc/health/v1/health.grpc.pb.h>`** matches stubs from **`@com_github_grpc_grpc//src/proto/grpc/health/v1:health_proto`** (same wire API as **`@grpc-proto//:health_proto`** used by Java). |
| **Backlog** | **BZ-035** (C++ proto in Bazel) — satisfied for **`currency`** in this fork via **BZ-092**. |

**What we implemented**

1. **`MODULE.bazel`** — **`bazel_dep(grpc, 1.66.0.bcr.2, repo_name = com_github_grpc_grpc)`**, **`bazel_dep(opentelemetry-cpp, 1.24.0.bcr.1)`**, **`bazel_dep(googletest, 1.14.0.bcr.1, repo_name = com_google_googletest)`**. **`single_version_override`** for **`protobuf` 29.3**, **`grpc` 1.66.0.bcr.2**, **`abseil-cpp` 20240116.1** so the resolved graph does not upgrade to **protobuf 33** / **grpc 1.69** (that combination breaks gRPC C++’s expected **protobuf / upb** targets). Bzlmod may still warn that **`rules_java`**, **`rules_python`**, or **`googletest`** resolved to newer versions than the root pins; builds were validated with the current lockfile.  
2. **`pb/BUILD.bazel`** — **`demo_cc_proto`**, **`demo_cc_grpc`** (**`grpc_only = True`**), **`demo_cpp_grpc`** wrapper **`cc_library`** for optional **`//pb:demo_cpp_grpc`** consumers.  
3. **`src/currency/currency_includes.bzl`** + **`currency_grpc_gen_includes`** — small rule providing **`CcInfo`** with extra **`includes`** (**`-I`**) for **`$(bin_dir)/src/currency`** and **`$(bin_dir)/external/grpc~/src/proto`**, because native **`cc_proto_library` / `cc_grpc_library`** + **`#include <…>`** did not receive the right include roots on this graph without it. The **`grpc~`** segment follows BCR’s external repository naming; if Bazel changes it, adjust **`currency_includes.bzl`**.  
4. **`src/currency/BUILD.bazel`** — **`genrule`** **`currency_demo_proto_copy`**; **`proto_library`** **`currency_demo_proto`**; **`cc_proto_library`** / **`cc_grpc_library`** (**`grpc_only`**); **`cc_library` `currency_lib`** (**`features = ["-pic"]`**, **`src/**/*.cpp`/`*.h`**, OTel + **`grpc`** + **`grpc++`** + health **`health_proto`**); **`cc_binary` `currency`**; **`cc_test` `currency_proto_smoke_test`** (**`tags = ["unit"]`**, **`cc_proto`** only — no gRPC **`.so`** link); **`mtree_spec`** / **`oci_image` `currency_image`** / **`oci_load` `currency_load`** (**`otel/demo-currency:bazel`**).  
5. **OCI** — Same pattern as **`shipping`**: **glibc-linked** binary → **`distroless_cc_debian13_nonroot`**, **`7001/tcp`** aligned with **`.env` `CURRENCY_PORT`**.

**Verification**

```bash
bazel build //src/currency:currency //src/currency:currency_image --config=ci
bazel test //src/currency:currency_proto_smoke_test --config=ci
bazel test //src/currency:currency_proto_smoke_test --config=unit
# optional: bazel run //src/currency:currency_load && docker image ls | grep otel/demo-currency
```

**Status in this repository:** **Implemented** (**B** / **T** / **I**). CMake/Docker remain alternate entrypoints.

---

### 7.3 Service: `src/email` — Ruby (BZ-093)

| Field | Detail |
|-------|--------|
| **Stack** | Sinatra + OpenTelemetry Ruby + Bundler; **`.ruby-version`** **3.4.8**. |
| **Build today** | **`src/email/Dockerfile`**: **Alpine** + **`bundle install`** → **`bundle exec ruby email_server.rb`**. |
| **Proto** | Service does not compile **`pb/demo.proto`** in-process (no gRPC server in this app). **`google-protobuf`** is a RubyGem dependency of OTLP exporters. |

**Why the Bazel OCI base differs from the Dockerfile**

- **`rules_ruby`** uses **portable MRI** (**glibc** on Linux). Native extensions in **`@email_bundle`** are built for that ABI.
- The **Compose** image stays **Alpine (musl)**; **`bundle install`** there selects **musl** **grpc** / **protobuf** gems. That path remains valid after lockfile updates (verified with **`docker build -f src/email/Dockerfile .`**).
- The **Bazel** image uses **`docker.io/library/ruby:3.4.8-slim-bookworm`** (digest **`ruby_348_slim_bookworm`** in **`MODULE.bazel`**) so the same **vendor/bundle** layout from Bazel is compatible at runtime.

**`Gemfile.lock` / Bundler**

- **`PLATFORMS`** are **`x86_64-linux`** and **`aarch64-linux`** only so **`rb_bundle_install`** (inside **`@email_bundle`**) does not require a single **grpc** version that satisfies **musl + darwin + gnu** at once (Bundler’s “all resolution platforms” rule).
- **`gem "google-protobuf", …, force_ruby_platform: true`** keeps **protobuf** on the generic Ruby platform where helpful; **`grpc`** remains platform-specific per Linux arch (**`-gnu`**).

**What we implemented**

1. **`MODULE.bazel`** — **`bazel_dep(rules_ruby, 0.24.0)`**; **`ruby.toolchain`** (**`portable_ruby = True`**, **`version_file = "//src/email:.ruby-version"`**); **`ruby.bundle_fetch`** **`name = "email_bundle"`**; **`use_repo`** + **`register_toolchains("@ruby_toolchains//:all")`**; **`oci.pull`** **`ruby_348_slim_bookworm`**.  
2. **`src/email/BUILD.bazel`** — **`rb_library` `email_lib`** (**`email_server.rb`**, **`views/**`**, **`deps = ["@email_bundle"]`**); **`rb_binary` `email`**; **`rb_test` `email_gems_smoke_test`** (**`test/gems_load_test.rb`**, **`tags = ["unit"]`**); **`pkg_tar`** **`email_bundle_layer`** (output of **`@email_bundle//:email_bundle`**) + **`email_app_layer`**; **`oci_image` `email_image`** / **`oci_load` `email_load`** (**`otel/demo-email:bazel`**, **`6060/tcp`**, **`WORKDIR`** **`/email_server`**).  
3. **`src/email/test/gems_load_test.rb`** — requires **Bundler** + **`sinatra/base`** (not **`sinatra`**, which in classic mode would start a server and hang **`rb_test`**).

**Verification**

```bash
bazel build //src/email:email //src/email:email_image --config=ci
bazel test //src/email:email_gems_smoke_test --config=ci
bazel test //src/email:email_gems_smoke_test --config=unit
# optional: bazel run //src/email:email_load && docker image ls | grep otel/demo-email
```

**Status in this repository:** **Implemented** (**B** / **T** / **I**). Dockerfile / **`bundle install`** remain alternate entrypoints.

---

### 7.4 Service: `src/flagd-ui` — Elixir / Phoenix (BZ-094)

| Field | Detail |
|-------|--------|
| **Stack** | **Phoenix 1.8** / **LiveView**, **Bandit**, **Mix**; **esbuild** + **Tailwind** asset pipeline; **heroicons** via **git** dependency. |
| **Build today** | **`src/flagd-ui/Dockerfile`**: **hexpm/elixir** builder (**1.19.3** / **OTP 28.0.2** / **Debian bullseye**), **`mix release`**, **Debian slim** runtime. |
| **Proto** | UI service; no **`pb/demo.proto`** compile step in this app. |

**Why a custom `mix_release` rule instead of BCR `rules_elixir`**

- **`rules_elixir`** (Rabbitmq / BCR) focuses on **Erlang/Elixir sources** with **`rules_erlang`**-style graphs; it does **not** replace **Mix** for a full **Phoenix** + **Hex** + **git deps** + **assets.deploy** pipeline.
- This fork follows the same pattern as **.NET** **`dotnet_publish`**: a **`run_shell`** rule copies declared sources into a **temp tree**, runs **`mix`** with **`MIX_ENV=prod`**, and emits a **`declare_directory`** output — **`//src/flagd-ui:flagd_ui_publish`**.
- **Trade-offs:** requires **host** **`mix`** (versions aligned with **`Dockerfile`**), **`gcc`** / **`build-essential`** for native deps, **`git`** for **heroicons**, and **network** (**`tags = ["requires-network"]`** on **`flagd_ui_publish`**). First builds can take **several minutes** (Hex fetch + compilation).

**Tests**

- **`//src/flagd-ui:flagd_ui_mix_test`** is an **`sh_test`** that **`cd`**s into runfiles-resolved **`src/flagd-ui`**, runs **`mix deps.get`** and **`mix test`**, **`tags = ["unit", "requires-network"]`**, **`size = "enormous"`** (long timeout). It **re-fetches** Mix deps independently of **`flagd_ui_publish`** (no shared **`_build`** between the two actions).

**OCI**

- **`pkg_tar`** **`flagd_ui_release_layer`** packs **`flagd_ui_publish`** under **`/app`**.
- **`oci_image`** **`flagd_ui_image`** uses **`debian_bullseye_20251117_slim_linux_amd64`** (digest-pinned index **`sha256:530a3348fc4b5734ffe1a137ddbcee6850154285251b53c3425c386ea8fac77b`** — same tag as **`Dockerfile`** **`RUNNER_IMAGE`**).
- **Caveat:** the **Dockerfile** **`apt-get`** layer adds **`ca-certificates`** and **`locales`**; **slim** may omit **`ca-certificates`** — see **`docs/bazel/oci-policy.md`** (**Elixir (`flagd-ui`)**). **Runtime** still needs **`SECRET_KEY_BASE`**, **`OTEL_EXPORTER_OTLP_ENDPOINT`**, etc. (**`config/runtime.exs`**).

**What we implemented**

1. **`MODULE.bazel`** — **`oci.pull`** **`debian_bullseye_20251117_slim`** + **`use_repo`** entries.  
2. **`tools/bazel/mix_release.bzl`** — **`mix_release`** rule.  
3. **`src/flagd-ui/BUILD.bazel`** — **`filegroup`** sources; **`mix_release` `flagd_ui_publish`**; **`sh_test` `flagd_ui_mix_test`** (**`run_mix_test.sh`**); **`pkg_tar`**; **`oci_image` / `oci_load`**.  
4. **`.github/workflows/checks.yml`** — **`erlef/setup-beam`** (**1.19.3** / **28.0.2**), **`apt`** **`build-essential`** **`git`**, **`bazel build`** / **`bazel test`** for **`//src/flagd-ui/...`**.

**Verification**

```bash
bazel build //src/flagd-ui:flagd_ui_publish //src/flagd-ui:flagd_ui_image --config=ci
bazel test //src/flagd-ui:flagd_ui_mix_test --config=ci
bazel test //src/flagd-ui:flagd_ui_mix_test --config=unit
# optional: bazel run //src/flagd-ui:flagd_ui_load && docker image ls | grep otel/demo-flagd-ui
```

**Status in this repository:** **Implemented** (**B** / **T** / **I**). **`mix phx.server`** / **`docker build -f src/flagd-ui/Dockerfile .`** remain alternate entrypoints.

---

### 7.5 Service: `src/quote` — PHP (BZ-095)

| Field | Detail |
|-------|--------|
| **Stack** | **PHP 8.3+** (demo **Dockerfile** uses **8.4**), **Slim 4**, **PHP-DI**, **React HTTP** server in **`public/index.php`**, **OpenTelemetry** PHP packages (**Composer**). |
| **Build today** | **`src/quote/Dockerfile`**: multi-stage — **`composer:2.8.12`** runs **`composer install`** (prod-only, no lockfile), then **`php:8.4-cli-alpine3.22`** + **`install-php-extensions`** (**`opcache`**, **`pcntl`**, **`protobuf`**, **`opentelemetry`**), **`WORKDIR /var/www`**, **`USER www-data`**, **`CMD ["php", "public/index.php"]`**. |
| **Proto** | **gRPC** consumer in the broader demo; this service does not compile **`pb/demo.proto`** in-tree (HTTP API only). |

**Why a custom `composer_install` rule**

- **BCR** does not expose a maintained **`rules_php`** + **Composer** graph that matches this app’s **Packagist** dependencies and **Slim** layout.
- Same pattern as **.NET** **`dotnet_publish`** and **Elixir** **`mix_release`**: a **`run_shell`** action copies a **declared manifest** of files into a **temp tree**, runs **`composer install`** with flags aligned to the **Dockerfile** vendor stage, and writes a **`declare_directory`** — **`//src/quote:quote_publish`**.
- **Trade-offs:** requires **host** **`php`** and **`composer`** (CI: **`shivammathur/setup-php`** with **PHP 8.4** + **Composer**), and **network** (**`tags = ["requires-network"]`** on **`quote_publish`**). There is **no** **`composer.lock`** in the repo; resolution is **floating** within **`composer.json`** constraints (same as **`docker build`** for this service).

**Tests**

- **`//src/quote:quote_composer_smoke_test`** is an **`sh_test`** (**`run_composer_smoke_test.sh`**) that resolves **`src/quote`** under **`$TEST_SRCDIR`**, runs **`composer install`** with the same prod flags, then **`php -r 'require "vendor/autoload.php";'`**. It is tagged **`unit`** and **`requires-network`**, **`size = "enormous"`**. It does **not** start the HTTP server. There is **no** **`phpunit`** suite in-tree yet; a future **`composer.lock`** + **`phpunit`** could add stricter tests.

**OCI**

- **`pkg_tar`** **`quote_app_layer`** packs **`quote_publish`** under **`var/www`** so the container matches **`WORKDIR /var/www`**.
- **`oci_image`** **`quote_image`** uses **`php_84_cli_alpine322_linux_amd64`** (index digest **`sha256:1029d5513f254a17f41f8384855cb475a39f786e280cf261b99d2edef711f32d`** — **`docker buildx imagetools inspect php:8.4-cli-alpine3.22`**).
- **`entrypoint`** **`["php", "public/index.php"]`** matches **`Dockerfile`** **`CMD`**. **`8090/tcp`** matches **`.env`** **`QUOTE_PORT`**.
- **Caveat:** **Dockerfile** installs **PECL** extensions; the Bazel **OCI** base does **not** — see **`docs/bazel/oci-policy.md`** (**PHP (`quote`)**). **`docker run`** must pass **`QUOTE_PORT`** (and OTLP env vars as needed).

**What we implemented**

1. **`MODULE.bazel`** — **`oci.pull`** **`php_84_cli_alpine322`** + **`use_repo`** entries.  
2. **`tools/bazel/composer_install.bzl`** — **`composer_install`** rule.  
3. **`src/quote/BUILD.bazel`** — **`filegroup`** **`quote_release_srcs`**; **`composer_install` `quote_publish`**; **`sh_test` `quote_composer_smoke_test`**; **`pkg_tar`**; **`oci_image` / `oci_load`**.  
4. **`.github/workflows/checks.yml`** — **`shivammathur/setup-php`** (**8.4** + **Composer**), **`bazel build`** / **`bazel test`** for **`//src/quote/...`**.

**Verification**

```bash
bazel build //src/quote:quote_publish //src/quote:quote_image --config=ci
bazel test //src/quote:quote_composer_smoke_test --config=ci
bazel test //src/quote:quote_composer_smoke_test --config=unit
# optional: bazel run //src/quote:quote_load && docker run --rm -e QUOTE_PORT=8090 -p 8090:8090 otel/demo-quote:bazel
```

**Status in this repository:** **Implemented** (**B** / **T** / **I**). **`docker compose build quote`** remains the entrypoint for **extension** parity with **`install-php-extensions`**.

---

### 7.6 Service: `src/react-native-app` — Expo / React Native, **Android only** (BZ-096)

| Field | Detail |
|-------|--------|
| **Stack** | **Expo 51** / **Expo Router**, **React Native 0.74**, **TypeScript**; **Android** via **Gradle 9.4** wrapper + **React Native Gradle plugin** (invokes **Node** for Metro / **expo export:embed**). |
| **Build today** | **`npm run android`** / **`expo run:android`**; **Docker** **`android.Dockerfile`** (**`reactnativecommunity/react-native-android`** image). **iOS** uses **Pods** + **Xcode** — **out of scope** for Bazel in this fork. |
| **Proto** | Generated **`protos/demo.ts`** (**ts-proto**, **gRPC** imports). **`@grpc/grpc-js`** is a **devDependency** so **`tsc --noEmit`** passes in CI without bundling gRPC into the RN runtime. |

**Goals**

1. **Test in CI** without Android Emulator: **`rn_js_checks`** (**`npm ci`**, **`tsc`**, **`jest`** with **`--passWithNoTests`** until real tests exist).  
2. **Optional APK** on **Linux x86_64** with a **hermetic** SDK + JDK **inside `@rn_android_sdk`**, so developers are **not** required to align **`ANDROID_HOME`** or **SDKMAN’s Java** with the demo — Bazel still uses **host `node` / `npm`** (Expo’s engine is **Node ≥ 18**; CI uses **22**).

**Hermetic `@rn_android_sdk` (what “hermetic” means here)**

- **`MODULE.bazel`** registers **`use_extension("//tools/bazel/rn_android:extension.bzl", "rn_android_sdk")`** → **`use_repo(..., "rn_android_sdk")`**.  
- **`tools/bazel/rn_android/sdk_repo.bzl`** implements **`rn_android_sdk_repository`**:  
  - **Downloads** pinned **Temurin 17.0.13+11** (`OpenJDK17U-jdk_x64_linux_hotspot_17.0.13_11.tar.gz`, **SHA-256** pinned).  
  - **Downloads** pinned **Android cmdline-tools** (`commandlinetools-linux-11076708_latest.zip`, **SHA-256** pinned).  
  - **Installs** into a single tree under the external repo: **`jdk/`**, **`sdk/`** (via **`sdkmanager`** with **`yes | sdkmanager --licenses`** then package list).  
  - **Packages** match **`android/build.gradle`**: **`platforms;android-34`**, **`build-tools;34.0.0`**, **`platform-tools`**, **`ndk;26.1.10909125`**.  
- **Lazy fetch:** nothing is downloaded until a target **depends** on **`@rn_android_sdk//:root`** (today: **`android_debug_apk` only**). **`rn_js_checks`** does **not** touch the Android SDK.  
- **OS support:** **linux-amd64 only** — the repository rule **`fail()`s** on **macOS** / non-amd64 with a pointer to **Docker** / local Android Studio. Extending **aarch64** or **Darwin** means adding the matching **cmdline-tools** / **JDK** URLs and checksums to **`sdk_repo.bzl`**.

**SDKMAN and host JDK (explicit separation)**

- Many developers install **Java** via **[SDKMAN](https://sdkman.io/)** (`sdk install java …`) for **Gradle**, **Kotlin**, or other JVM tools. **That is unrelated to Bazel’s APK build:**  
  - **`android_debug_apk`** sets **`JAVA_HOME`** and **`ANDROID_SDK_ROOT`** from **`dirname(@rn_android_sdk//:root)`** — i.e. **`…/jdk`** and **`…/sdk`** inside the external repository.  
  - **`GRADLE_USER_HOME`** is a **fresh temp directory** per action so the rule does not reuse your **`~/.gradle`** caches (trade-off: colder builds, better isolation).  
- **Corollary:** you **do not** need to “point Bazel at SDKMAN”. Conversely, **SDKMAN does not replace** **`@rn_android_sdk`** for this target.

**Why `no-sandbox` on `android_debug_apk`**

- **Gradle** reads **many** files under **`ANDROID_SDK_ROOT`** and **NDK** outputs; listing them all as Bazel inputs would be **impractical**. **`tags = ["no-sandbox"]`** allows the tool to read the **pre-fetched** SDK tree while the **app sources** are still **declared** via **`filegroup`** + manifest copy.

**Why `manual`**

- First **`@rn_android_sdk`** resolution can take **a long time** and **large disk**. **CI** runs **`rn_js_checks` only**; **`android_debug_apk`** is for **opt-in** local or dedicated jobs:  
  `bazel build //src/react-native-app:android_debug_apk`.

**iOS**

- **No** **`bazel build`** / **`bazel test`** targets under **`ios/`**. Continue using **README** iOS sections and **Xcode**.

**What we implemented**

1. **`MODULE.bazel`** — **`rn_android`** module extension + **`use_repo` `rn_android_sdk`**.  
2. **`tools/bazel/rn_android/sdk_repo.bzl`**, **`extension.bzl`**, **`rn_gradle_apk.bzl`**, **`BUILD.bazel`**.  
3. **`src/react-native-app/BUILD.bazel`** — **`rn_app_srcs`** (**`glob`** excludes **`ios/**`**, **`node_modules/**`**, build outputs); **`rn_js_checks`**; **`android_debug_apk`**.  
4. **`src/react-native-app/run_rn_js_checks.sh`**, tracked **`expo-env.d.ts`**, **`.gitignore`** adjusted.  
5. **`package.json` / `package-lock.json`** — **`@grpc/grpc-js`** devDependency for **`tsc`**.  
6. **`.github/workflows/checks.yml`** — **`bazel test //src/react-native-app:rn_js_checks`**.

**Verification**

```bash
bazel test //src/react-native-app:rn_js_checks --config=ci
bazel test //src/react-native-app:rn_js_checks --config=unit
# Optional (linux-amd64; long first run):
# bazel build //src/react-native-app:android_debug_apk --config=ci
```

**Status in this repository:** **Implemented** (**B** / **T** for Android + JS); **no** Bazel **iOS**; **no** **`oci_image`** (APK artifact only).

---

### 7.7 `src/frontend-proxy` / `src/image-provider` — Envoy / nginx (**BZ-097**)

| Field | Detail |
|-------|--------|
| **Stacks** | **Envoy** reverse proxy (**`envoy.tmpl.yaml`**); **nginx** static file server + OpenTelemetry module (**`nginx.conf.template`**, **`static/**`**). |
| **Build today** | **`Dockerfile`** each: **`gettext-base`** (Envoy only), **`envsubst` at container start** so Compose can override upstream hostnames and ports. |
| **Proto** | Neither service compiles **`pb/demo.proto`**. |

**Why bake at build time instead of `envsubst` in the image**

- **`rules_oci`** layering does not mirror **`RUN apt-get install gettext-base`** on the stock Envoy base the way the **Dockerfile** does, and we avoid extra mutable layers for a small demo edge case.
- **`bake_envoy.sh`** / **`bake_nginx.sh`** run **`envsubst` on the Bazel host** (or CI runner) during **`genrule`**, producing a **fixed** **`envoy.yaml`** / **`nginx.conf`** embedded in **`pkg_tar`** layers. Defaults match **`.env`** / **docker-compose** service DNS names (**`frontend`**, **`otel-collector`**, **`image-provider`**, …).
- **Implication:** to change upstreams in the Bazel image, **rebuild** with env vars exported before **`bazel build`**, or keep using **`docker compose build`** for runtime substitution parity.

**`frontend-proxy` — what we implemented**

1. **`MODULE.bazel`** — **`oci.pull`** **`envoy_v134_latest`** (**`docker.io/envoyproxy/envoy`**, tag **`v1.34-latest`**, multi-arch index digest **`sha256:a27ac382cb5f4d3bebb665a4f557a8e96266a724813e1b89a6fb0b31d4f63a39`**). **`use_repo`** exports **`envoy_v134_latest_linux_amd64`** / **`arm64`**.
2. **`src/frontend-proxy/BUILD.bazel`** — **`genrule` `envoy_compose_defaults_yaml`** (**`tags = ["no-sandbox"]`**) invokes **`bake_envoy.sh`**; **`pkg_tar` `frontend_proxy_envoy_layer`** → **`/etc/envoy/envoy.yaml`**; **`oci_image` `frontend_proxy_image`** (**`entrypoint`** **`["/usr/local/bin/envoy"]`**, **`cmd`** **`["-c", "/etc/envoy/envoy.yaml"]`**, **`8080/tcp`**, **`10000/tcp`**); **`oci_load` `frontend_proxy_load`** → **`otel/demo-frontend-proxy:bazel`**.
3. **`sh_test` `frontend_proxy_config_test`** — **`run_frontend_proxy_config_test.sh`** re-bakes and asserts YAML shape (**`unit`**, **`no-sandbox`**).

**`image-provider` — what we implemented**

1. **`MODULE.bazel`** — **`oci.pull`** **`nginx_unprivileged_1290_alpine322_otel`** (**`docker.io/nginxinc/nginx-unprivileged`**, tag **`1.29.0-alpine3.22-otel`**, multi-arch index digest **`sha256:5a41b6424e817a6c97c057e4be7fb8fdc19ec95845c784487dee1fa795ef4d03`**).
2. **`src/image-provider/BUILD.bazel`** — **`genrule` `nginx_compose_defaults_conf`**; **`pkg_tar` `image_provider_static_layer`** (**`/static`**); **`pkg_tar` `image_provider_nginx_layer`** → **`/etc/nginx/nginx.conf`**; **`oci_image` `image_provider_image`** (**`user = "101"`**, **`entrypoint`** **`["/usr/sbin/nginx"]`**, **`cmd`** **`["-g", "daemon off;"]`**, **`8081/tcp`**); **`oci_load` `image_provider_load`** → **`otel/demo-image-provider:bazel`**.
3. **`sh_test` `image_provider_config_test`** — **`run_image_provider_config_test.sh`** (**`unit`**, **`no-sandbox`**). **`bake_nginx.sh`** uses the same **`envsubst '$…'`** variable list as the **Dockerfile** **`CMD`**.

**Prerequisites**

- **`envsubst`** (**Debian/Ubuntu: `gettext-base`**) on any machine that runs the **`genrule`** or the **`sh_test`**s. **CI:** **`.github/workflows/checks.yml`** installs **`gettext-base`** alongside **`build-essential`** / **`git`**.

**Verification**

```bash
bazel build //src/frontend-proxy:frontend_proxy_image //src/image-provider:image_provider_image --config=ci
bazel test //src/frontend-proxy:frontend_proxy_config_test //src/image-provider:image_provider_config_test --config=ci
# optional:
# bazel run //src/frontend-proxy:frontend_proxy_load
# bazel run //src/image-provider:image_provider_load
# docker image ls | grep -E 'demo-frontend-proxy:bazel|demo-image-provider:bazel'
```

**Status in this repository:** **Implemented** (**B** / **T** / **I** for both). **`docs/bazel/oci-policy.md`** (**Envoy** / **nginx** subsections) and **`docs/bazel/service-tracker.md`** list **B/T/I**.

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

**Done in this fork (doc-level):** `docs/bazel/oci-policy.md` selects **`rules_oci`**, digest-pinned bases, and documents **BZ-121** + **BZ-097** on **checkout** (Go), **payment** (Node / **js_image_layer**), **frontend** (Next + **nodejs24** distroless), **Python** services (**`rules_pkg`** **`pkg_tar(include_runfiles)`** + **`docker.io/library/python:3.12-slim-bookworm`**), **JVM** **`ad` / `fraud-detection`** (**deploy JAR** + **distroless Java** — **§9.6**), **.NET `accounting`** and **.NET `cart`** (**`dotnet publish`** + **aspnet** — **§9.7**, **§9.9**), **Rust `shipping`** (**`rust_binary`** + **distroless cc** — **§9.8**), **C++ `currency`** (**`cc_binary`** + **distroless cc** — **§9.10**), **Ruby `email`** (**`rules_ruby`** **`bundle_fetch`** + **`ruby:3.4.8-slim-bookworm`** — **§9.11**), **Elixir `flagd-ui`** (**`mix_release`** + **`debian:bullseye-slim`** — **§9.12**), **PHP `quote`** (**`composer_install`** + **`php:8.4-cli-alpine3.22`** — **§9.13**), **Envoy `frontend-proxy`** and **nginx `image-provider`** (**baked configs** — **§9.14** / **`oci-policy.md`**).

### 9.2 BZ-121 — Pilot image (`checkout`, Go)

**Choice:** **`src/checkout`** (Go) — already built as **`//src/checkout:checkout`** in M2; static Linux binary fits **`gcr.io/distroless/static-debian12`** (nonroot).

**Module wiring (`MODULE.bazel`):**

- **`bazel_dep`:** `rules_oci` 2.3.0, `aspect_bazel_lib` 2.21.1, `tar.bzl` 0.7.0, **`rules_pkg`** 1.0.1 (Python service **`pkg_tar`** layers).
- **`oci.pull`** defines digest-pinned bases: **`distroless_static_debian12_nonroot`** (checkout), **`distroless_cc_debian13_nonroot`** (Rust **shipping**), **`distroless_nodejs22_debian12_nonroot`** / **`distroless_nodejs24_debian13_nonroot`** (Node), **`python_312_slim_bookworm`** (Python), **`dotnet_aspnet_10`** (**`mcr.microsoft.com/dotnet/aspnet`** **10.0**), **`ruby_348_slim_bookworm`** (Ruby **email**), **`debian_bullseye_20251117_slim`** (Elixir **flagd-ui** runtime), **`php_84_cli_alpine322`** (PHP **quote** — **`docker.io/library/php:8.4-cli-alpine3.22`** index), **`envoy_v134_latest`** (**Envoy `frontend-proxy`**), **`nginx_unprivileged_1290_alpine322_otel`** (**nginx `image-provider`**), each for **`linux/amd64`** and **`linux/arm64`** where applicable (see `MODULE.bazel` for digests).
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

### 9.6 BZ-121 — Extension: JVM (**`ad`**, **`fraud-detection`**)

**What we added**

1. **`MODULE.bazel`** — two **`oci.pull`** roots: **`distroless_java21_debian12_nonroot`** (index digest **`sha256:7e37784d94dccbf5ccb195c73b295f5ad00cd266512dfbac12eb9c3c28f8077d`**, **`gcr.io/distroless/java21-debian12`**, **amd64** + **arm64** manifests) and **`distroless_java17_debian12_nonroot`** (**`sha256:06484c2a9dcc9070aeafbc0fe752cb9f73bc0cea5c311f6a516e9010061998ad`**, **`gcr.io/distroless/java17-debian12`**). **`use_repo`** exports **`*_linux_amd64`** / **`*_linux_arm64`** variants (images pin **linux/amd64** bases today, same pattern as **`checkout`** / Python).

2. **`tools/bazel/java_oci.bzl`** — **`java_deploy_jar_oci`**: **`pkg_tar`** of the **`java_binary`** implicit **`_deploy.jar`** into **`usr/src/app/`**, then **`oci_image`** with **`entrypoint = ["/usr/bin/java", "-jar", "/usr/src/app/<jar>"]`**, **`workdir = "/usr/src/app"`**, **`oci_load`** with **`otel/demo-*:bazel`** tags.

3. **`src/ad/BUILD.bazel`** — **`java_deploy_jar_oci`** **`name = "ad_oci"`** → **`ad_oci_image`**, **`ad_oci_load`**; **`exposed_ports = ["9555/tcp"]`** (**.env** **`AD_PORT`**).

4. **`src/fraud-detection/BUILD.bazel`** — **`fraud_detection_oci_*`** on **Java 17** base; no exposed ports (Kafka consumer only).

**Verification**

```bash
bazel build //src/ad:ad_oci_image //src/fraud-detection:fraud_detection_oci_image --config=ci
bazel run //src/ad:ad_oci_load
bazel run //src/fraud-detection:fraud_detection_oci_load
docker image ls | grep -E 'demo-ad:bazel|demo-fraud-detection:bazel'
```

**Caveats**

- **OTel Java agent:** not included in Bazel-built images (upstream Dockerfiles **`ADD`** **`opentelemetry-javaagent.jar`** and set **`JAVA_TOOL_OPTIONS`**). Add a **`pkg_tar`** layer or **`env`** on **`oci_image`** for parity.  
- **`bazel_smoke`** builds **`ad_oci_image`** and **`fraud_detection_oci_image`** (not **`oci_load`**) to keep CI artifact-only.

**Next (BZ-122 / M4):** align **`component-build-images.yml`**, registry push (**BZ-123**), optional **multi-arch** **`oci_image` `base`** selection.

### 9.7 BZ-121 — Extension: .NET **`accounting`**

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** **`dotnet_aspnet_10`** for **`mcr.microsoft.com/dotnet/aspnet`** (multi-arch index digest **`sha256:a04d1c1d2d26119049494057d80ea6cda25bbd8aef7c444a1fc1ef874fd3955b`**), with **`use_repo`** for **`dotnet_aspnet_10_linux_amd64`** / **`dotnet_aspnet_10_linux_arm64`** (image **`base`** pins **linux/amd64** today).

2. **`src/accounting/BUILD.bazel`** — **`pkg_tar`** **`accounting_layer`** from **`accounting_publish`** with **`package_dir = "app"`** (matches **`WORKDIR /app`** in **`src/accounting/Dockerfile`**). **`oci_image`** **`accounting_image`**: **`entrypoint`** **`["./instrument.sh", "dotnet", "Accounting.dll"]`**, **`env`** **`OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES=Accounting.Consumer`**, **`oci_load`** **`accounting_load`** → **`otel/demo-accounting:bazel`**.

**Verification**

```bash
bazel build //src/accounting:accounting_image //src/accounting:accounting_load --config=ci
bazel run //src/accounting:accounting_load
docker image ls | grep otel/demo-accounting
```

**Caveats**

- **Log dir:** Dockerfile **`RUN mkdir -p /var/log/opentelemetry/dotnet`** + **`chown`** is **not** in the Bazel layer yet.  
- **`bazel_smoke`** builds **`accounting_image`** (same pattern as other **`*_image`** targets; **`oci_load`** is optional locally).

### 9.8 BZ-121 — Extension: Rust **`shipping`**

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** **`distroless_cc_debian13_nonroot`** for **`gcr.io/distroless/cc-debian13`** (multi-arch index digest **`sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e`**), aligned with **`src/shipping/Dockerfile`** (**`:nonroot`**). **`use_repo`** exports **`distroless_cc_debian13_nonroot_{linux_amd64,linux_arm64}`**.

2. **`src/shipping/BUILD.bazel`** — same **`aspect_bazel_lib`** **`mtree_spec`** / **`mtree_mutate`** / **`tar`** pattern as **`checkout`**, but **`package_dir = "app"`** so the binary is **`/app/shipping`**. **`oci_image`** **`shipping_image`**: **`base`** = **`@distroless_cc_debian13_nonroot_linux_amd64//:...`**, **`entrypoint`** **`["./shipping"]`**, **`workdir`** **`/app`**, **`exposed_ports`** **`["50050/tcp"]`** (**.env** **`SHIPPING_PORT`**). **`oci_load`** **`shipping_load`** → **`otel/demo-shipping:bazel`**.

**Why `cc` not `static`:** the default **`rules_rust`** Linux target (**`x86_64-unknown-linux-gnu`**) produces a **dynamically linked** binary (glibc). **`gcr.io/distroless/static`** lacks glibc — use **`static`** only if you move to a **musl** / fully static link strategy.

**Verification**

```bash
bazel build //src/shipping:shipping_image //src/shipping:shipping_load --config=ci
bazel run //src/shipping:shipping_load
docker image ls | grep otel/demo-shipping
```

**Caveats**

- **`bazel_smoke`** builds **`shipping_image`** (not **`shipping_load`**) like other JVM / Go OCI targets.  
- **Multi-arch:** **`oci_image` `base`** is **linux/amd64** today; **`oci.pull`** still fetches **arm64** for future native or cross builds.

### 9.9 BZ-121 — Extension: .NET **`cart`**

**What we added**

1. **`//tools/bazel:dotnet_publish.bzl`** — **`proto_dest`** (default **`src/protos/demo.proto`**) and **`extra_publish_args`**; manifest destinations use **paths relative to the Bazel package** so nested trees (**`src/cart/src/...`**) copy correctly (see **§6.2**).

2. **`src/cart/BUILD.bazel`** — **`cart_publish`** (**`proto_dest = "pb/demo.proto"`**, **`extra_publish_args`** disables single-file / self-contained publish), **`pkg_tar`** **`cart_layer`**, **`oci_image`** **`cart_image`** on **`@dotnet_aspnet_10_linux_amd64//:...`**, **`entrypoint`** **`["dotnet", "cart.dll"]`**, **`7070/tcp`**, **`oci_load`** **`cart_load`** → **`otel/demo-cart:bazel`**.

**Verification**

```bash
bazel build //src/cart:cart_image //src/cart:cart_load --config=ci
```

**Caveats**

- **Not** a byte-for-byte match to **`src/cart/src/Dockerfile`** (musl single-file vs **FDD** on **aspnet**).  
- **`bazel_ci`** / **`ci_full.sh`** builds **`cart_image`** and runs **`//src/cart:cart_dotnet_test`**.

### 9.10 BZ-121 — Extension: C++ **`currency`**

**What we added**

1. **`src/currency/BUILD.bazel`** — **`aspect_bazel_lib`** **`mtree_spec`** / **`mtree_mutate`** (**`package_dir = "app"`**) / **`tar`** over **`//src/currency:currency`**; **`oci_image`** **`currency_image`** with **`base`** = **`@distroless_cc_debian13_nonroot_linux_amd64//:...`**, **`entrypoint`** **`["./currency"]`**, **`cmd`** **`["7001"]`** (default port; override at **`docker run`**), **`workdir`** **`/app`**, **`exposed_ports`** **`["7001/tcp"]`**. **`oci_load`** **`currency_load`** → **`otel/demo-currency:bazel`**.  
2. **Runtime** — Binary is **dynamically linked** (**gRPC**, **opentelemetry-cpp**, **protobuf**); **distroless cc** matches the **glibc** expectation (same class as **Rust `shipping`**).  
3. **Stock Dockerfile** used **`ENTRYPOINT ["sh", "-c", "./usr/local/bin/currency ${CURRENCY_PORT}"]`**; the Bazel image has **no shell** — pass the port as **container args** (e.g. **`docker run … otel/demo-currency:bazel 7001`**) or set **`cmd`** when rebaking the image.

**Verification**

```bash
bazel build //src/currency:currency_image //src/currency:currency_load --config=ci
# optional: bazel run //src/currency:currency_load && docker run --rm -p 7001:7001 otel/demo-currency:bazel 7001
```

**Caveats**

- **`bazel_smoke`** builds **`currency_image`** (not **`currency_load`**) like other **`*_image`** targets.  
- **`currency_includes.bzl`** hard-codes the **`grpc~`** external folder name for **`health`** includes; if resolution changes, update that rule.

### 9.11 BZ-121 — Extension: Ruby **`email`**

**What we added**

1. **`MODULE.bazel`** — **`rules_ruby`** + **`ruby_348_slim_bookworm`** **`oci.pull`** (index digest **`sha256:1af92319c7301866eddd99a7d43750d64afa1f2b96d9a4cb45167d759e865a85`** for **`docker.io/library/ruby:3.4.8-slim-bookworm`**).  
2. **`src/email/BUILD.bazel`** — two **`pkg_tar`** layers (**`@email_bundle//:email_bundle`** → **`/email_server`**, then app sources); **`oci_image`** **`email_image`** (**`entrypoint`** **`["bundle", "exec", "ruby", "email_server.rb"]`**, **`workdir`** **`/email_server`**, **`6060/tcp`**); **`oci_load`** **`email_load`** → **`otel/demo-email:bazel`**.

**Verification**

```bash
bazel build //src/email:email_image //src/email:email_load --config=ci
# optional: bazel run //src/email:email_load && docker run --rm -e EMAIL_PORT=6060 -p 6060:6060 otel/demo-email:bazel
```

**Caveats**

- **Base image** is **Debian slim** (glibc), not **Alpine** — see **§7.3**.  
- **`bazel_smoke`** builds **`email_image`** (not **`email_load`**) like other OCI targets.

### 9.12 BZ-121 — Extension: Elixir **`flagd-ui`**

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** **`debian_bullseye_20251117_slim`** (index digest **`sha256:530a3348fc4b5734ffe1a137ddbcee6850154285251b53c3425c386ea8fac77b`**).  
2. **`src/flagd-ui/BUILD.bazel`** — **`pkg_tar`** **`flagd_ui_release_layer`**; **`oci_image`** **`flagd_ui_image`** (**`entrypoint`** mirrors **`Dockerfile`** **`CMD`** via **`/app/bin/server`**); **`oci_load`** **`flagd_ui_load`** → **`otel/demo-flagd-ui:bazel`**; **`4000/tcp`**.

**Verification**

```bash
bazel build //src/flagd-ui:flagd_ui_image //src/flagd-ui:flagd_ui_load --config=ci
# optional: bazel run //src/flagd-ui:flagd_ui_load && docker run --rm -e SECRET_KEY_BASE="$(mix phx.gen.secret)" -e OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4317 -e FLAGD_UI_PORT=4000 -p 4000:4000 otel/demo-flagd-ui:bazel
```

**Caveats**

- **`bazel_smoke`** builds **`flagd_ui_publish`** and **`flagd_ui_image`**; **`mix test`** is a separate **`sh_test`** (duplicate Mix fetch).  
- **§7.4** / **`oci-policy.md`**: **ca-certificates** / **locale** parity vs **`Dockerfile`**.

### 9.13 BZ-121 — Extension: PHP **`quote`**

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** **`php_84_cli_alpine322`** (index digest **`sha256:1029d5513f254a17f41f8384855cb475a39f786e280cf261b99d2edef711f32d`** for **`docker.io/library/php:8.4-cli-alpine3.22`**).  
2. **`tools/bazel/composer_install.bzl`** — **`composer_install`** (**`run_shell`** + **`declare_directory`**).  
3. **`src/quote/BUILD.bazel`** — **`quote_publish`**; **`pkg_tar`** **`quote_app_layer`** under **`var/www`**; **`oci_image`** **`quote_image`** (**`entrypoint`** **`["php", "public/index.php"]`**); **`oci_load`** **`quote_load`** → **`otel/demo-quote:bazel`**; **`8090/tcp`**.  
4. **`src/quote/run_composer_smoke_test.sh`** + **`sh_test`** **`quote_composer_smoke_test`** (**`unit`**, **`requires-network`**).

**Verification**

```bash
bazel build //src/quote:quote_publish //src/quote:quote_image //src/quote:quote_load --config=ci
bazel test //src/quote:quote_composer_smoke_test --config=ci
# optional: bazel run //src/quote:quote_load && docker run --rm -e QUOTE_PORT=8090 -e OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4317 -p 8090:8090 otel/demo-quote:bazel
```

**Caveats**

- **`bazel_smoke`** builds **`quote_publish`** and **`quote_image`**; **`quote_composer_smoke_test`** runs a **second** **`composer install`** (no shared **`vendor/`** between the action and the test).  
- **§7.5** / **`oci-policy.md`**: **PECL** extensions (**`opentelemetry`**, **`protobuf`**, …) from **`install-php-extensions`** are **not** in the Bazel base image.

### 9.14 BZ-097 — Extension: Envoy **`frontend-proxy`** + nginx **`image-provider`**

**What we added**

1. **`MODULE.bazel`** — **`oci.pull`** roots **`envoy_v134_latest`** and **`nginx_unprivileged_1290_alpine322_otel`** with **`use_repo`** for **linux/amd64** and **linux/arm64** manifests (images pin **amd64** bases today, same pattern as **`checkout`**).  
2. **`src/frontend-proxy/`** — **`bake_envoy.sh`** + **`genrule`** + **`pkg_tar`** + **`oci_image` / `oci_load`** + **`frontend_proxy_config_test`**.  
3. **`src/image-provider/`** — **`bake_nginx.sh`** + **`genrule`** + two **`pkg_tar`** layers + **`oci_image` / `oci_load`** + **`image_provider_config_test`**.  
4. **`.github/workflows/checks.yml`** — **`gettext-base`** on the runner; **`bazel build`** both **`*_image`** targets; **`bazel test`** both config **`sh_test`**s.

**Verification**

```bash
bazel build //src/frontend-proxy:frontend_proxy_image //src/image-provider:image_provider_image --config=ci
bazel test //src/frontend-proxy:frontend_proxy_config_test //src/image-provider:image_provider_config_test --config=ci
```

**Caveats**

- **Runtime `envsubst`** vs **bake-time** substitution — see **§7.7** and **`oci-policy.md`** (**Envoy** / **nginx** rows).  
- **`bazel_smoke`** builds **`frontend_proxy_image`** and **`image_provider_image`** (not **`oci_load`**) like other OCI targets.

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

**Ongoing:** When adding **`py_test`**, **`rust_test`**, **`cc_test`**, **`rb_test`**, **`sh_test`** (or other runners), or **`js_test`** under M3+, apply the same tags (**`unit`** / **`manual`** / **`integration`** per **`docs/bazel/test-tags.md`**); Gazelle does not add tags automatically. The four Python services above have **no** in-tree tests yet, so no **`py_test`** targets were added. **`//src/shipping:shipping_test`** is tagged **`unit`** (**BZ-090**). **`//src/currency:currency_proto_smoke_test`** is tagged **`unit`** (**BZ-092** — protobuf smoke only; no gRPC **`cc_test`** yet). **`//src/email:email_gems_smoke_test`** is tagged **`unit`** (**BZ-093** — Bundler + gem load smoke). **`//src/flagd-ui:flagd_ui_mix_test`** is tagged **`unit`** (**BZ-094** — **`mix test`**, **`requires-network`**). **`//src/quote:quote_composer_smoke_test`** is tagged **`unit`** (**BZ-095** — **`composer install`** + **`vendor/autoload.php`** smoke, **`requires-network`**). **`//src/react-native-app:rn_js_checks`** is tagged **`unit`** (**BZ-096** — **`npm ci`**, **`tsc`**, **`jest`**, **`requires-network`**). **`//src/frontend-proxy:frontend_proxy_config_test`** and **`//src/image-provider:image_provider_config_test`** are tagged **`unit`** (**BZ-097** — baked Envoy/nginx config smoke, **`no-sandbox`**).

---

## 11. Suggested order inside M3

Aligned with **§22 Suggested implementation order** in the backlog (items 8–12, 16 partial):

1. **BZ-120 / BZ-121** — OCI policy + pilot image (proves end-to-end artifact story).  
2. **BZ-051** or **BZ-090** — one “hard” language (Next or Rust) to de-risk.  
3. **BZ-060 / BZ-061** — Python wave starting with **`recommendation`**.  
4. **BZ-070 / BZ-071** — JVM (shared Maven pin helps both).  
5. **BZ-080 / BZ-121** — .NET **`accounting`** + **`cart`** (**`accounting_*`**, **`cart_publish`** / **`cart_image`**) — **done** in this fork (§6, §6.2, §9.7, §9.9).  
6. **BZ-090 / BZ-121** — Rust **`shipping`** (build, test, **`shipping_image`**) — **done** in this fork (§7, §9.8).  
6b. **BZ-092 / BZ-121** — C++ **`currency`** (build, **`cc_test`**, **`currency_image`**) — **done** in this fork (§7.2, §9.10).  
6c. **BZ-093 / BZ-121** — Ruby **`email`** (**`rules_ruby`**, **`rb_test`**, **`email_image`**) — **done** in this fork (§7.3, §9.11).  
6d. **BZ-094 / BZ-121** — Elixir **`flagd-ui`** (**`mix_release`**, **`sh_test`**, **`flagd_ui_image`**) — **done** in this fork (§7.4, §9.12).  
6e. **BZ-095 / BZ-121** — PHP **`quote`** (**`composer_install`**, **`sh_test`**, **`quote_image`**) — **done** in this fork (§7.5, §9.13).  
6f. **BZ-096** — Expo **`react-native-app`** (**Android only** — **`@rn_android_sdk`**, **`rn_js_checks`**, **`android_debug_apk`**) — **done** in this fork (§7.6).  
6g. **BZ-097** — Envoy **`frontend-proxy`** + nginx **`image-provider`** (**baked configs**, **`oci_image`**, config **`sh_test`**) — **done** in this fork (§7.7, §9.14).  
7. **BZ-130** — **Done** (taxonomy + docs); extend tags as new test rules land.

---

## 12. Verification cheat sheet

**Already available (M2 + M1):**

```bash
bazel build //:smoke //pb:demo_proto //pb:go_grpc_protos //pb:demo_py_grpc //pb:demo_java_grpc //pb:demo_cpp_grpc --config=ci
bazel build //src/ad:ad //src/fraud-detection:fraud_detection --config=ci
bazel build //src/ad:ad_oci_image //src/fraud-detection:fraud_detection_oci_image --config=ci
bazel build //src/accounting:accounting_publish //src/accounting:accounting_image --config=ci
bazel build //src/cart:cart_publish //src/cart:cart_image --config=ci   # BZ-081 + BZ-121
bazel test //src/cart:cart_dotnet_test --config=ci   # BZ-081 xUnit (M4)
bazel build //src/checkout/... //src/product-catalog/... //src/payment:payment --config=ci
bazel build //src/recommendation:recommendation //src/product-reviews:product_reviews //src/llm:llm //src/load-generator:load_generator --config=ci
bazel build //src/recommendation:recommendation_image //src/product-reviews:product_reviews_image //src/llm:llm_image //src/load-generator:load_generator_image --config=ci
bazel build //src/shipping:shipping //src/shipping:shipping_image --config=ci   # BZ-090 + BZ-121 OCI
bazel build //src/currency:currency //src/currency:currency_image --config=ci   # BZ-092 + BZ-121 OCI
bazel build //src/email:email //src/email:email_image --config=ci   # BZ-093 + BZ-121 OCI
bazel build //src/flagd-ui:flagd_ui_publish //src/flagd-ui:flagd_ui_image --config=ci   # BZ-094 + BZ-121 OCI (host mix)
bazel build //src/quote:quote_publish //src/quote:quote_image --config=ci   # BZ-095 + BZ-121 OCI (host PHP + Composer)
bazel build //src/frontend-proxy:frontend_proxy_image //src/image-provider:image_provider_image --config=ci   # BZ-097 (host gettext / envsubst)
bazel test  //src/checkout/... //src/product-catalog/... --config=ci
bazel test  //src/shipping/... --config=ci      # BZ-090 (rust_test)
bazel test  //src/currency:currency_proto_smoke_test --config=ci   # BZ-092 (cc_test, unit)
bazel test  //src/email:email_gems_smoke_test --config=ci   # BZ-093 (rb_test, unit)
bazel test  //src/flagd-ui:flagd_ui_mix_test --config=ci   # BZ-094 (sh_test / mix test, unit)
bazel test  //src/quote:quote_composer_smoke_test --config=ci   # BZ-095 (sh_test / composer + autoload, unit)
bazel test  //src/react-native-app:rn_js_checks --config=ci   # BZ-096 (npm ci + tsc + jest, unit)
bazel test  //src/frontend-proxy:frontend_proxy_config_test //src/image-provider:image_provider_config_test --config=ci   # BZ-097 (baked config smoke)
bazel test  //src/frontend:lint --config=ci   # BZ-051 (Next ESLint)
bazel test  //src/checkout/money:money_test //src/shipping:shipping_test //src/currency:currency_proto_smoke_test //src/email:email_gems_smoke_test //src/flagd-ui:flagd_ui_mix_test //src/quote:quote_composer_smoke_test //src/react-native-app:rn_js_checks //src/frontend-proxy:frontend_proxy_config_test //src/image-provider:image_provider_config_test --config=unit
bazel test  //... --config=unit   # all tests tagged `unit` (see docs/bazel/test-tags.md)
bazel build //src/checkout:checkout_image //src/checkout:checkout_load --config=ci   # BZ-121 (checkout)
bazel build //src/payment:payment_image //src/payment:payment_load --config=ci       # BZ-121 (payment)
bazel build //src/frontend:frontend_image //src/frontend:frontend_load --config=ci   # BZ-121 (frontend)
```

**Still to add (other M3 backlog items):**

```bash
# e.g. further BZ-122 rollout, registry push, etc.
```

---

## Related documents

| Document | Purpose |
|----------|---------|
| `docs/planification/5-bazel-migration-task-backlog.md` | Source of truth for task IDs and milestones. |
| `docs/bazel/milestones/m1-completion.md` | Proto graph (M1). |
| `docs/bazel/milestones/m2-completion.md` | Go + payment (M2). |
| `docs/bazel/proto-policy.md` | Proto single source / drift policy. |
| `docs/bazel/go-toolchain.md` | Go SDK / Gazelle (M2). |
| `docs/bazel/oci-policy.md` | BZ-120 OCI direction. |
| `docs/bazel/test-tags.md` | BZ-130 test tag convention. |
| `docs/bazel/service-tracker.md` | Per-service B/T/I/CI snapshot. |
| `docs/bazel/milestones/m4-completion.md` | **M4** playbook — CI Bazel-first, BZ-122/123, BZ-631, BZ-081, BZ-110, BZ-611–613. |
| `docs/bazel/milestones/m5-completion.md` | **M5** playbook — BZ-633, BZ-720–723, BZ-132/133, BZ-632, BZ-800, BZ-811/812. |

---

*This file should be updated whenever a service moves from “Not started” to buildable: add the concrete target labels, `MODULE.bazel` pins, and CI lines in the relevant section and in `service-tracker.md`. For **M4** planning, see **`m4-completion.md`**.*
