# OCI / container image policy (BZ-120)

This note records the **chosen direction** for building container images with Bazel in this fork, per **`5-bazel-migration-task-backlog.md`** epic **M — OCI images** (BZ-120).

## Decision (M3)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| **Rule set** | **`rules_oci`** (Bazel Central Registry) for `oci_image` / layering | Hermetic, Bzlmod-friendly, aligns with modern Bazel OCI workflows; avoids legacy `container_image` patterns where possible. |
| **Base images** | **Pin by digest** in `MODULE.bazel` via **`oci.pull`** | Reproducibility and supply-chain review (feeds later BZ-720 policy). |
| **Pilot (BZ-121)** | **`checkout`** (Go) + **`payment`** (Node) + **`frontend`** (Next) + **four Python services** + **JVM `ad` / `fraud-detection`** + **.NET `accounting`** + **.NET `cart`** + **Rust `shipping`** — **`oci_image`** + **`oci_load`** each | Proves Go (**static** distroless), Node, Next, Python, JVM, .NET (**aspnet** for **`accounting`** + **`cart`**), and Rust (**`rust_binary`** + **distroless `cc`**): digest-pinned bases, layering, `docker load`. |

## BZ-121 pilot (implemented)

### `checkout` (Go)

| Item | Detail |
|------|--------|
| **Image / load** | `//src/checkout:checkout_image`, `//src/checkout:checkout_load` → **`otel/demo-checkout:bazel`**. |
| **Base** | `gcr.io/distroless/static-debian12` @ **`sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1`** (**linux/amd64** / **arm64** pull; image uses **amd64** base today). |
| **Layout** | Static binary at **`/usr/src/app/checkout`**, **`WORKDIR`** `/usr/src/app`, **5050/tcp**. |

### `payment` (Node)

| Item | Detail |
|------|--------|
| **Image / load** | `//src/payment:payment_image`, `//src/payment:payment_load` → **`otel/demo-payment:bazel`**. |
| **Base** | `gcr.io/distroless/nodejs22-debian12` (nonroot index digest **`sha256:13593b7570658e8477de39e2f4a1dd25db2f836d68a0ba771251572d23bb4f8e`** in **`MODULE.bazel`**). |
| **Layers** | **`js_image_layer`** runfiles split; **`oci_image`** stacks **package_store** + **node_modules** + **app** (no duplicate **`node`** layer — uses distroless **`/nodejs/bin/node`**). |
| **Runtime** | Same shape as **`src/payment/Dockerfile`**: **`/nodejs/bin/node`**, **`--require=./opentelemetry.js`**, **`index.js`**, **50051/tcp**. |

### `frontend` (Next.js)

| Item | Detail |
|------|--------|
| **Image / load** | `//src/frontend:frontend_image`, `//src/frontend:frontend_load` → **`otel/demo-frontend:bazel`**. |
| **Base** | `gcr.io/distroless/nodejs24-debian13` (nonroot; digest-pinned in **`MODULE.bazel`**, aligned with **`src/frontend/Dockerfile`**). |
| **Layer** | Single **`tar`** from **`copy_to_directory`** over **`js_run_binary`** **`next_build`** outputs (standalone layout + **`public/`** + **`Instrumentation.js`**). |
| **Runtime** | **`WORKDIR`** **`/app`**, **`/nodejs/bin/node`**, **`--require=./Instrumentation.js`**, **`server.js`**, **8080/tcp**. |

**`next build`** uses **`tags = ["manual", "no-sandbox"]`** (standalone symlink tracing). Narrative, Connect/protobuf lock notes, and troubleshooting: **`docs/bazel/milestones/m3-completion.md`** §8–§9.

### Python (`recommendation`, `product-reviews`, `llm`, `load-generator`)

| Item | Detail |
|------|--------|
| **Image / load** | `//src/recommendation:recommendation_{image,load}` → **`otel/demo-recommendation:bazel`**; **`product_reviews_{image,load}`** → **`otel/demo-product-reviews:bazel`**; **`llm_{image,load}`** → **`otel/demo-llm:bazel`**; **`load_generator_{image,load}`** → **`otel/demo-load-generator:bazel`**. |
| **Base** | **`docker.io/library/python`** **`3.12-slim-bookworm`** (multi-arch index digest in **`MODULE.bazel`** as **`python_312_slim_bookworm`**). |
| **Layers** | **`rules_pkg`** **`pkg_tar`** with **`include_runfiles = True`** on each **`py_binary`**; files under **`/app/<name>`** + **`/app/<name>.runfiles/`**; macro **`//tools/bazel:py_oci.bzl`** **`py_binary_oci`**. |
| **Runtime** | **`ENTRYPOINT`** **`/app/<py_binary name>`**; **`WORKDIR`** **`/app`**. Ports align with **`.env`** defaults (**9001**, **3551**, **8000**, **8089**). |
| **Caveat** | **`load-generator`**: Bazel image includes Locust + Playwright **Python** deps only — **not** **`playwright install`** browsers; use **`src/load-generator/Dockerfile`** for full Playwright parity. |

### JVM (`ad`, `fraud-detection`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/ad:ad_oci_image`**, **`//src/ad:ad_oci_load`** → **`otel/demo-ad:bazel`**; **`//src/fraud-detection:fraud_detection_oci_image`**, **`//src/fraud-detection:fraud_detection_oci_load`** → **`otel/demo-fraud-detection:bazel`**. |
| **Base** | **`gcr.io/distroless/java21-debian12`** (multi-arch index digest **`sha256:7e37784d94dccbf5ccb195c73b295f5ad00cd266512dfbac12eb9c3c28f8077d`**) for **`ad`** — matches Java **21** in **`src/ad/Dockerfile`**. **`gcr.io/distroless/java17-debian12`** (index **`sha256:06484c2a9dcc9070aeafbc0fe752cb9f73bc0cea5c311f6a516e9010061998ad`**) for **`fraud-detection`** — matches **`src/fraud-detection/Dockerfile`**. |
| **Layers** | **`rules_pkg`** **`pkg_tar`** of the implicit **`java_binary` deploy JAR** (`*_deploy.jar`) under **`/usr/src/app/`**; macro **`//tools/bazel:java_oci.bzl`** **`java_deploy_jar_oci`**. |
| **Runtime** | **`ENTRYPOINT`** **`/usr/bin/java -jar /usr/src/app/<deploy>.jar`**; **`WORKDIR`** **`/usr/src/app`**. **`ad`** exposes **9555/tcp** (demo **AD_PORT**). **`fraud-detection`** is a Kafka consumer — **no** **`exposed_ports`** in the image. |
| **Caveat** | Upstream Dockerfiles add the **OpenTelemetry Java agent** via **`JAVA_TOOL_OPTIONS`**. Bazel images do **not** bundle the agent by default; add a second **`pkg_tar`** layer or **`env`** on **`oci_image`** if you need parity with **`docker compose`**. |

### .NET (`accounting`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/accounting:accounting_image`**, **`//src/accounting:accounting_load`** → **`otel/demo-accounting:bazel`**. |
| **Base** | **`mcr.microsoft.com/dotnet/aspnet`** **10.0** (multi-arch index digest **`sha256:a04d1c1d2d26119049494057d80ea6cda25bbd8aef7c444a1fc1ef874fd3955b`** in **`MODULE.bazel`** as **`dotnet_aspnet_10`**). |
| **Layers** | **`rules_pkg`** **`pkg_tar`** of **`accounting_publish`** under **`/app`** (**`package_dir = "app"`**). |
| **Runtime** | **`ENTRYPOINT`** **`./instrument.sh dotnet Accounting.dll`** (**OpenTelemetry .NET auto-instrumentation** from the publish tree), **`WORKDIR`** **`/app`**, **`OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES=Accounting.Consumer`**. |
| **Caveat** | **`src/accounting/Dockerfile`** creates **`/var/log/opentelemetry/dotnet`** and **`chown`** for **`app`**; the Bazel image omits that unless you add another **`pkg_tar`**. Build **`accounting_publish`** needs **.NET 10** on the host and network for NuGet (**`requires-network`**). |

### .NET (`cart`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/cart:cart_image`**, **`//src/cart:cart_load`** → **`otel/demo-cart:bazel`**. |
| **Base** | Same **`dotnet_aspnet_10`** (**`mcr.microsoft.com/dotnet/aspnet:10.0`**, digest in **`MODULE.bazel`**) as **`accounting`**. |
| **Layers** | **`rules_pkg`** **`pkg_tar`** of **`cart_publish`** under **`/app`**. |
| **Runtime** | **`ENTRYPOINT`** **`dotnet cart.dll`**, **`WORKDIR`** **`/app`**, **7070/tcp** (demo **`CART_PORT`**). Requires **`VALKEY_ADDR`** (and OTLP env as needed), same as Compose. |
| **Caveat** | **`src/cart/src/Dockerfile`** builds a **musl** **single-file** **`./cart`** on **`runtime-deps:alpine`**. Bazel uses **framework-dependent** **`cart.dll`** on **aspnet** (see **`docs/bazel/milestones/m3-completion.md`** §6.2). **`dotnet test`** for **`tests/cart.tests.csproj`** is not a **`bazel test`** target yet. |

### Rust (`shipping`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/shipping:shipping_image`**, **`//src/shipping:shipping_load`** → **`otel/demo-shipping:bazel`**. |
| **Base** | **`gcr.io/distroless/cc-debian13:nonroot`** (multi-arch index digest **`sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e`** in **`MODULE.bazel`** as **`distroless_cc_debian13_nonroot`**). Matches **`src/shipping/Dockerfile`** final stage. |
| **Layers** | **`aspect_bazel_lib`** **`mtree_spec`** / **`mtree_mutate`** / **`tar`** (same pattern as **`checkout`**) with **`package_dir = "app"`** — binary at **`/app/shipping`**. |
| **Runtime** | **`ENTRYPOINT`** **`./shipping`**, **`WORKDIR`** **`/app`**, **50050/tcp** (demo **`SHIPPING_PORT`**). Requires **`SHIPPING_PORT`** (and OTLP endpoints if exporting) at **`docker run`**, same as Docker Compose. |
| **Caveat** | Default **`rules_rust`** Linux binary is **dynamically linked** to **glibc** — use **`distroless/cc`**, not **`distroless/static`**. A **musl** / fully static build could move to **`static`** later. **`oci_image`** **`base`** is **linux/amd64** today (see **`checkout`** platform note). |

## Out of scope at BZ-120

- Full matrix parity with **`component-build-images.yml`** (BZ-122, **M4**).
- Push targets and secrets (BZ-123, **M4**).

## References

- Milestone narrative: `docs/bazel/milestones/m3-completion.md` (Epic M, BZ-120–121).
- Service tracker: `docs/bazel/service-tracker.md`.
