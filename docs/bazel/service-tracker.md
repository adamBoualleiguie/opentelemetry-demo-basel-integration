# Service Bazel migration tracker

Snapshot through **M2** (Go checkout + product-catalog build/test; payment Node `js_binary`). Update as milestones progress.

Legend: **NS** = Not started | **P** = Proto in Bazel | **B** = Build | **T** = Test | **I** = Image | **CI** = CI gated on Bazel for this service

| Path | Language | Build entrypoint (today) | Proto consumer | Bazel proto (M1) | Status |
|------|----------|---------------------------|----------------|------------------|--------|
| `src/accounting` | .NET | Dockerfile / `dotnet` | Yes | — | NS |
| `src/ad` | Java | Gradle / Dockerfile | Yes | — | NS |
| `src/cart` | .NET | Dockerfile / `dotnet` | Yes | — | NS |
| `src/checkout` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_checkout` | B/T |
| `src/currency` | C++ | Dockerfile / cmake | Yes | — | NS |
| `src/email` | Ruby | Dockerfile / bundler | Yes | — | NS |
| `src/flagd-ui` | Elixir | Dockerfile / mix | Yes | — | NS |
| `src/fraud-detection` | Kotlin | Gradle / Dockerfile | Yes | — | NS |
| `src/frontend` | TS/Next | Dockerfile / npm | Yes | — | NS |
| `src/frontend-proxy` | Envoy | Dockerfile | No | — | NS |
| `src/image-provider` | nginx | Dockerfile | No | — | NS |
| `src/kafka` | infra | Dockerfile | No | — | NS |
| `src/llm` | Python | Dockerfile | No | — | NS |
| `src/load-generator` | Python | Dockerfile | No | — | NS |
| `src/opensearch` | infra | Dockerfile | No | — | NS |
| `src/payment` | Node | Dockerfile / npm | Yes | — | B |
| `src/product-catalog` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_product_catalog` | B/T |
| `src/product-reviews` | Python | Dockerfile | Yes | — | NS |
| `src/quote` | PHP | Dockerfile | Yes | — | NS |
| `src/react-native-app` | TS/RN | npm / Gradle (Android) | Yes | — | NS |
| `src/recommendation` | Python | Dockerfile | Yes | — | NS |
| `src/shipping` | Rust | Dockerfile / cargo | Yes | — | NS |

**Shared:** `pb/demo.proto` → `//pb:demo_proto` (all RPC services in one file).

**CI:** `.github/workflows/checks.yml` job **`bazel_smoke`** (`continue-on-error: true`) builds **`//src/checkout/...`**, **`//src/product-catalog/...`**, **`//src/payment:payment`** and runs Go tests for the two Go services.

Infra/config under `src/` (grafana, jaeger, prometheus, postgresql, otel-collector, flagd) are not listed above; track separately when image rules are introduced.
