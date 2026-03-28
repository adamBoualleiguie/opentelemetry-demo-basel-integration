# Service Bazel migration tracker

Snapshot through **M3** frontend OCI; playbook in **`docs/bazel/milestones/m3-completion.md`**. Update as milestones progress.

Legend: **NS** = Not started | **P** = Proto in Bazel | **B** = Build | **T** = Test | **I** = Image | **CI** = CI gated on Bazel for this service

| Path | Language | Build entrypoint (today) | Proto consumer | Bazel proto (M1) | Status |
|------|----------|---------------------------|----------------|------------------|--------|
| `src/accounting` | .NET | Dockerfile / `dotnet` | Yes | — | NS |
| `src/ad` | Java | Gradle / Dockerfile | Yes | — | NS |
| `src/cart` | .NET | Dockerfile / `dotnet` | Yes | — | NS |
| `src/checkout` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_checkout` | B/T/I |
| `src/currency` | C++ | Dockerfile / cmake | Yes | — | NS |
| `src/email` | Ruby | Dockerfile / bundler | Yes | — | NS |
| `src/flagd-ui` | Elixir | Dockerfile / mix | Yes | — | NS |
| `src/fraud-detection` | Kotlin | Gradle / Dockerfile | Yes | — | NS |
| `src/frontend` | TS/Next | Dockerfile / npm | Yes | — | B/T/I |
| `src/frontend-proxy` | Envoy | Dockerfile | No | — | NS |
| `src/image-provider` | nginx | Dockerfile | No | — | NS |
| `src/kafka` | infra | Dockerfile | No | — | NS |
| `src/llm` | Python | Dockerfile | No | — | NS |
| `src/load-generator` | Python | Dockerfile | No | — | NS |
| `src/opensearch` | infra | Dockerfile | No | — | NS |
| `src/payment` | Node | Dockerfile / npm | Yes | — | B/I |
| `src/product-catalog` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_product_catalog` | B/T |
| `src/product-reviews` | Python | Dockerfile | Yes | — | NS |
| `src/quote` | PHP | Dockerfile | Yes | — | NS |
| `src/react-native-app` | TS/RN | npm / Gradle (Android) | Yes | — | NS |
| `src/recommendation` | Python | Dockerfile | Yes | — | NS |
| `src/shipping` | Rust | Dockerfile / cargo | Yes | — | NS |

**Shared:** `pb/demo.proto` → `//pb:demo_proto` (all RPC services in one file).

**CI:** `.github/workflows/checks.yml` job **`bazel_smoke`** (`continue-on-error: true`) builds **`//src/checkout/...`**, **`//src/product-catalog/...`**, **`//src/payment/...`** (includes **`payment_image`** / **`payment_load`**), **`//src/frontend:frontend_image`**, runs Go tests for the two Go services, and runs **`bazel test //src/frontend:lint`** (**BZ-051**).

Infra/config under `src/` (grafana, jaeger, prometheus, postgresql, otel-collector, flagd) are not listed above; track separately when image rules are introduced.

**M3 (majority services + images):** see **`docs/bazel/milestones/m3-completion.md`** and **`docs/bazel/oci-policy.md`** (BZ-120). **BZ-121:** **`//src/checkout:checkout_{image,load}`**, **`//src/payment:payment_{image,load}`** (wildcard builds), **`//src/frontend:frontend_{image,load}`** (explicit target — **`next_build`** / image rules are **`manual`**).

**BZ-130 (test tags):** **`docs/bazel/test-tags.md`**; **`bazel test //... --config=unit`** runs only tests tagged **`unit`** (currently **`//src/checkout/money:money_test`**).
