# OCI / container image policy (BZ-120)

This note records the **chosen direction** for building container images with Bazel in this fork, per **`5-bazel-migration-task-backlog.md`** epic **M — OCI images** (BZ-120).

## Decision (M3)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| **Rule set** | **`rules_oci`** (Bazel Central Registry) for `oci_image` / layering | Hermetic, Bzlmod-friendly, aligns with modern Bazel OCI workflows; avoids legacy `container_image` patterns where possible. |
| **Base images** | **Pin by digest** in `MODULE.bazel` via **`oci.pull`** | Reproducibility and supply-chain review (feeds later BZ-720 policy). |
| **Pilot (BZ-121 + BZ-097)** | **`checkout`** (Go) + **`payment`** (Node) + **`frontend`** (Next) + **four Python services** + **JVM `ad` / `fraud-detection`** + **.NET `accounting`** + **.NET `cart`** + **Rust `shipping`** + **C++ `currency`** + **Ruby `email`** + **Elixir `flagd-ui`** + **PHP `quote`** + **Envoy `frontend-proxy`** + **nginx `image-provider`** — **`oci_image`** + **`oci_load`** each | Proves Go (**static** distroless), Node, Next, Python, JVM, .NET (**aspnet**), Rust (**`rust_binary`** + **distroless `cc`**), C++ (**distroless `cc`**), Ruby, Elixir (**`mix release`**), PHP, **Envoy** (**`envoyproxy/envoy`** + baked YAML), **nginx** (**`nginxinc/nginx-unprivileged`** OTEL + **`/static`**): digest-pinned bases, layering, `docker load`. |

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

### Ruby (`email`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/email:email_image`**, **`//src/email:email_load`** → **`otel/demo-email:bazel`**. |
| **Base** | **`docker.io/library/ruby`** **`3.4.8-slim-bookworm`** (multi-arch index digest **`sha256:1af92319c7301866eddd99a7d43750d64afa1f2b96d9a4cb45167d759e865a85`** in **`MODULE.bazel`** as **`ruby_348_slim_bookworm`**). **Glibc** — aligns with **`rules_ruby`** portable MRI and **`@email_bundle`** native extensions. |
| **Layers** | **`rules_pkg`** **`pkg_tar`**: **`email_bundle_layer`** (output of **`@email_bundle//:email_bundle`** — **`Gemfile`**, **`Gemfile.lock`**, **`vendor/bundle`**, binstubs) + **`email_app_layer`** (**`email_server.rb`**, **`views/`**, etc.) under **`/email_server`**. |
| **Runtime** | **`ENTRYPOINT`** **`bundle exec ruby email_server.rb`**, **`WORKDIR`** **`/email_server`**, **`6060/tcp`** (demo **`EMAIL_PORT`**). |
| **Caveat** | **`src/email/Dockerfile`** uses **Alpine** + **`bundle install`**; the Bazel image uses **Debian slim** by design (see **`docs/bazel/milestones/m3-completion.md`** §7.3). **`Gemfile.lock`** **`PLATFORMS`** are **`x86_64-linux`** / **`aarch64-linux`** for Bazel **`bundle install`**; Compose **Dockerfile** still works (**`docker build -f src/email/Dockerfile .`**). |

### Elixir (`flagd-ui`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/flagd-ui:flagd_ui_image`**, **`//src/flagd-ui:flagd_ui_load`** → **`otel/demo-flagd-ui:bazel`**. |
| **Build** | **`//src/flagd-ui:flagd_ui_publish`** — custom **`mix_release`** rule (**`//tools/bazel:mix_release.bzl`**) runs host **`mix release`** (same steps as **`src/flagd-ui/Dockerfile`** builder: **`deps.get`**, **`deps.compile`**, **`assets.setup`**, **`assets.deploy`**, **`compile`**, **`release`**). |
| **Base** | **`docker.io/library/debian`** **`bullseye-20251117-slim`** (multi-arch index digest **`sha256:530a3348fc4b5734ffe1a137ddbcee6850154285251b53c3425c386ea8fac77b`** in **`MODULE.bazel`** as **`debian_bullseye_20251117_slim`**). Aligns with the **final** stage of **`src/flagd-ui/Dockerfile`**. |
| **Layers** | **`rules_pkg`** **`pkg_tar`** **`flagd_ui_release_layer`** — contents of **`mix release`** under **`/app`** ( **`bin/server`**, embedded **ERTS**, etc.). |
| **Runtime** | **`ENTRYPOINT`** **`/bin/sh -c 'ulimit …; exec /app/bin/server'`**, **`WORKDIR`** **`/app`**, **`4000/tcp`** (demo **`FLAGD_UI_PORT`**). **`PHX_SERVER`** is set by **`rel/overlays/bin/server`**. |
| **Caveat** | The stock **Dockerfile** runs **`apt-get install`** for **`libstdc++6`**, **`openssl`**, **`libncurses5`**, **`locales`**, **`ca-certificates`**. **Official `debian:bullseye-slim`** already includes **`libssl1.1`**; it does **not** install **`ca-certificates`** by default — OTLP over **HTTPS** from the container may need an extra layer or use **`src/flagd-ui/Dockerfile`** for full parity. **Prod** still requires **`SECRET_KEY_BASE`**, **`OTEL_EXPORTER_OTLP_ENDPOINT`**, etc. (**`config/runtime.exs`**). |

### PHP (`quote`)

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/quote:quote_image`**, **`//src/quote:quote_load`** → **`otel/demo-quote:bazel`**. |
| **Build** | **`//src/quote:quote_publish`** — custom **`composer_install`** rule (**`//tools/bazel:composer_install.bzl`**) copies **`composer.json`**, **`app/`**, **`public/`**, **`src/`** into a temp tree and runs **`composer install`** with the same flags as the **Dockerfile** vendor stage (**`--ignore-platform-reqs`**, **`--no-dev`**, **`--no-plugins`**, **`--no-scripts`**, **`--prefer-dist`**). |
| **Base** | **`docker.io/library/php`** **`8.4-cli-alpine3.22`** (multi-arch index digest **`sha256:1029d5513f254a17f41f8384855cb475a39f786e280cf261b99d2edef711f32d`** in **`MODULE.bazel`** as **`php_84_cli_alpine322`**). Same **tag** as the **final** stage of **`src/quote/Dockerfile`**. |
| **Layers** | **`rules_pkg`** **`pkg_tar`** **`quote_app_layer`** — full tree (**`vendor/`** + app) under **`/var/www`**, matching **`WORKDIR`** in the **Dockerfile**. |
| **Runtime** | **`ENTRYPOINT`** **`["php", "public/index.php"]`**, **`WORKDIR`** **`/var/www`**, **`8090/tcp`** (demo **`QUOTE_PORT`** in **`.env`**). **`QUOTE_PORT`** must be set at **`docker run`** (the app reads **`getenv('QUOTE_PORT')`**). |
| **Caveat** | **`src/quote/Dockerfile`** installs **PECL** extensions via **`install-php-extensions`** (**`opcache`**, **`pcntl`**, **`protobuf`**, **`opentelemetry`**). The stock **`php:8.4-cli-alpine`** base used here does **not** run that step — **OpenTelemetry** for PHP may fall back to **pure PHP** auto-instrumentation where supported; for **full** extension parity (or **grpc**), build from **`src/quote/Dockerfile`** or add a custom base image. The **Dockerfile** also runs **`composer`** as **`USER www-data`**; the Bazel image runs as the image default user (**root** on this base unless you add **`user`** metadata — not set today). |

### Envoy (`frontend-proxy`) — BZ-097

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/frontend-proxy:frontend_proxy_image`**, **`frontend_proxy_load`** → **`otel/demo-frontend-proxy:bazel`**. |
| **Build** | **`genrule` `envoy_compose_defaults_yaml`** runs **`bake_envoy.sh`** (**`envsubst`**) on **`envoy.tmpl.yaml`** with defaults aligned to **`.env`** / **docker-compose** service hostnames (**`frontend`**, **`otel-collector`**, …). **`pkg_tar`** places **`/etc/envoy/envoy.yaml`**. |
| **Base** | **`docker.io/envoyproxy/envoy`** **`v1.34-latest`** (multi-arch index digest **`sha256:a27ac382cb5f4d3bebb665a4f557a8e96266a724813e1b89a6fb0b31d4f63a39`** in **`MODULE.bazel`** as **`envoy_v134_latest`**). |
| **Runtime** | **`ENTRYPOINT`** **`["/usr/local/bin/envoy"]`**, **`CMD`** **`["-c", "/etc/envoy/envoy.yaml"]`**, **`8080/tcp`** (**`ENVOY_PORT`**), **`10000/tcp`** (**`ENVOY_ADMIN_PORT`**). |
| **Caveat** | **`src/frontend-proxy/Dockerfile`** installs **`gettext-base`** and runs **`envsubst` at container start** so any env can override upstreams. The Bazel image **bakes** YAML at **build** time — to change upstreams, rebuild with different env passed to **`bake_envoy.sh`** or use **`docker compose build`**. **`genrule`** / tests need **`envsubst`** (**`gettext-base`**) on the host. |

### nginx (`image-provider`) — BZ-097

| Item | Detail |
|------|--------|
| **Image / load** | **`//src/image-provider:image_provider_image`**, **`image_provider_load`** → **`otel/demo-image-provider:bazel`**. |
| **Build** | **`genrule` `nginx_compose_defaults_conf`** runs **`bake_nginx.sh`** (**`envsubst`** with the same variable list as the **Dockerfile** **`CMD`**) on **`nginx.conf.template`**. **`pkg_tar`** layers: **`/static/**`** (assets) + **`/etc/nginx/nginx.conf`**. |
| **Base** | **`docker.io/nginxinc/nginx-unprivileged`** **`1.29.0-alpine3.22-otel`** (multi-arch index digest **`sha256:5a41b6424e817a6c97c057e4be7fb8fdc19ec95845c784487dee1fa795ef4d03`** in **`MODULE.bazel`** as **`nginx_unprivileged_1290_alpine322_otel`**). |
| **Runtime** | **`user`** **`101`**, **`ENTRYPOINT`** **`["/usr/sbin/nginx"]`**, **`CMD`** **`["-g", "daemon off;"]`**, **`8081/tcp`** (**`IMAGE_PROVIDER_PORT`**). |
| **Caveat** | **Dockerfile** runs **`envsubst` at start** and **`cat`**’s the config (debug). Bazel image uses **pre-baked** **`nginx.conf`** only. Stub **`/status`** remains in the template. |

## Out of scope at BZ-120

- Full matrix parity with **`component-build-images.yml`** (BZ-122, **M4**).
- Push targets and secrets (BZ-123, **M4**).

## References

- Milestone narrative: `docs/bazel/milestones/m3-completion.md` (Epic M, BZ-120–121; **BZ-097** edge images in **§7.7** / **§9.14**).
- Service tracker: `docs/bazel/service-tracker.md`.
