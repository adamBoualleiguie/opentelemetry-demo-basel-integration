# Service Bazel migration tracker

Snapshot through **M4** (CI Bazel-first slice): **`docs/bazel/milestones/m3-completion.md`** (services), **`docs/bazel/milestones/m4-completion.md`** (CI / matrix / push). **M5** (release-adjacent Bazel OCI for **checkout**, allowlist, unit sweep, SBOM/scan workflow): **`docs/bazel/milestones/m5-completion.md`**. Update as milestones progress.

Legend: **NS** = Not started | **P** = Proto in Bazel | **B** = Build | **T** = Test | **I** = Image | **CI** = included in **blocking** **`bazel_ci`** job (**`tools/bazel/ci/ci_full.sh`**)

| Path | Language | Build entrypoint (today) | Proto consumer | Bazel proto (M1) | Status |
|------|----------|---------------------------|----------------|------------------|--------|
| `src/accounting` | .NET | Dockerfile / `dotnet` | Yes | `//pb:demo.proto` → `src/protos` (Bazel) | B/I |
| `src/ad` | Java | Gradle / Dockerfile | Yes | `//pb:demo_java_grpc` | B/I |
| `src/cart` | .NET | Dockerfile / `dotnet` | Yes | `//pb:demo.proto` → **`pb/demo.proto`** in publish tree (Bazel) | B/T/I |
| `src/checkout` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_checkout` | B/T/I |
| `src/currency` | C++ | Dockerfile / cmake | Yes | `//pb:demo.proto` → genrule copy + `proto_library` in `//src/currency` (**BZ-092**); optional **`//pb:demo_cpp_grpc`** for other C++ consumers | B/T/I |
| `src/email` | Ruby | Dockerfile / bundler | Yes | — | B/T/I |
| `src/flagd-ui` | Elixir | Dockerfile / mix | Yes | — | B/T/I |
| `src/fraud-detection` | Kotlin | Gradle / Dockerfile | Yes | `//pb:demo_java_grpc` | B/I |
| `src/frontend` | TS/Next | Dockerfile / npm | Yes | — | B/T/I |
| `src/frontend-proxy` | Envoy | Dockerfile / Bazel baked YAML | No | — | B/T/I |
| `src/image-provider` | nginx | Dockerfile / Bazel baked nginx.conf | No | — | B/T/I |
| `src/kafka` | infra | Dockerfile | No | — | Dockerfile (**BZ-110**) |
| `src/llm` | Python | Dockerfile | No | — | B/I |
| `src/load-generator` | Python | Dockerfile | No | — | B/I |
| `src/opensearch` | infra | Dockerfile | No | — | Dockerfile (**BZ-110**) |
| `src/payment` | Node | Dockerfile / npm | Yes | — | B/I |
| `src/product-catalog` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_product_catalog` | B/T |
| `src/product-reviews` | Python | Dockerfile | Yes | `//pb:demo_py_grpc` | B/I |
| `src/quote` | PHP | Dockerfile / Composer | Yes | — | B/T/I |
| `src/react-native-app` | TS/RN (Expo) | npm / Gradle (**Android only** in Bazel) | Yes | — | B/T |
| `src/recommendation` | Python | Dockerfile | Yes | `//pb:demo_py_grpc` | B |
| `src/shipping` | Rust | Dockerfile / cargo | Yes | — (proto in Bazel TBD) | B/T/I |

**Shared:** `pb/demo.proto` → `//pb:demo_proto` (all RPC services in one file).

## Infra / config images (**BZ-110**, M4)

Paths under **`src/`** used mainly for Compose; **no** Bazel **`oci_image`** in this fork unless noted.

| Path | Strategy | Bazel target | Notes |
|------|----------|--------------|--------|
| `src/kafka` | Dockerfile only | — | Matrix **`tag_suffix: kafka`**. |
| `src/opensearch` | Dockerfile only | — | Matrix **`tag_suffix: opensearch`**. |
| `src/grafana` | Config volume / upstream image | — | **`docker-compose.yml`** mounts **`src/grafana/`**; no local **`Dockerfile`** in tree. |
| `src/jaeger` | Dockerfile only | — | If present under **`src/jaeger`**. |
| `src/prometheus` | Dockerfile only | — | |
| `src/postgresql` | Dockerfile only | — | |
| `src/otel-collector` | Dockerfile only | — | |
| `src/flagd` | Dockerfile only | — | |
| `src/frontend-proxy` | **Dual** | `//src/frontend-proxy:frontend_proxy_image` | Also in app table (**BZ-097**). |
| `src/image-provider` | **Dual** | `//src/image-provider:image_provider_image` | Also in app table (**BZ-097**). |

## CI (**M4**)

**`.github/workflows/checks.yml`** job **`bazel_ci`** (**blocking**) runs **`bash ./tools/bazel/ci/ci_full.sh`**, which performs **`bazel build`** and **`bazel test`** for the migrated graph (protos, binaries, **`*_image`** targets listed in the script), **`//src/cart:cart_dotnet_test`** (**BZ-081**), and **`bazel run //:lint`**. **`.NET 10`**, **Node 22**, **Python**, **Elixir/OTP**, **PHP/Composer**, **gettext-base**, and **Go** toolchains match the prior inline smoke job. **`actions/cache`** caches **`~/.cache/bazel`** (**BZ-613**). An optional PR step prints **`tools/bazel/ci/affected_targets.sh`** hints (**BZ-612**).

**Dual publish:** registry images still come from **`component-build-images.yml`** (Dockerfile matrix). See **`docs/bazel/oci-policy.md`** (**BZ-122**) and **`docs/bazel/oci-registry-push.md`** (**BZ-123** — **`//src/checkout:checkout_push`**).

**M3 (majority services + images):** see **`docs/bazel/milestones/m3-completion.md`** and **`docs/bazel/oci-policy.md`** (BZ-120). **BZ-121** + **BZ-097:** application services above with **`oci_image`** as documented.

**BZ-130 (test tags):** **`docs/bazel/test-tags.md`**; **`bazel test //... --config=unit`** includes **`//src/cart:cart_dotnet_test`** (also **`requires-network`**, **`no-sandbox`**).

**Cypress / BZ-131:** **`docs/bazel/frontend-cypress-bazel.md`** (deferred from default Bazel graph).
