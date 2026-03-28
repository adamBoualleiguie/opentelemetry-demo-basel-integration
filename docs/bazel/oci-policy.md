# OCI / container image policy (BZ-120)

This note records the **chosen direction** for building container images with Bazel in this fork, per **`5-bazel-migration-task-backlog.md`** epic **M — OCI images** (BZ-120).

## Decision (M3)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| **Rule set** | **`rules_oci`** (Bazel Central Registry) for `oci_image` / layering | Hermetic, Bzlmod-friendly, aligns with modern Bazel OCI workflows; avoids legacy `container_image` patterns where possible. |
| **Base images** | **Pin by digest** in `MODULE.bazel` via **`oci.pull`** | Reproducibility and supply-chain review (feeds later BZ-720 policy). |
| **Pilot (BZ-121)** | **`checkout`** (Go) + **`payment`** (Node) + **`frontend`** (Next) + **four Python services** — **`oci_image`** + **`oci_load`** each | Proves Go, Node, Next, and Python (**`rules_pkg`** `pkg_tar` + **`py_binary`** runfiles) paths: digest-pinned bases, layering, `docker load`. |

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

## Out of scope at BZ-120

- Full matrix parity with **`component-build-images.yml`** (BZ-122, **M4**).
- Push targets and secrets (BZ-123, **M4**).

## References

- Milestone narrative: `docs/bazel/milestones/m3-completion.md` (Epic M, BZ-120–121).
- Service tracker: `docs/bazel/service-tracker.md`.
