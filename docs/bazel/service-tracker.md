# Service Bazel migration tracker

Snapshot for **M0** (pre–language migration). Update statuses as milestones progress.

Legend: **NS** = Not started | **P** = Proto only | **B** = Build | **T** = Test | **I** = Image | **CI** = CI gated on Bazel for this service

| Path | Language | Build entrypoint (today) | Proto consumer | Status (M0) |
|------|----------|---------------------------|----------------|-------------|
| `src/accounting` | .NET | Dockerfile / `dotnet` | Yes | NS |
| `src/ad` | Java | Gradle / Dockerfile | Yes | NS |
| `src/cart` | .NET | Dockerfile / `dotnet` | Yes | NS |
| `src/checkout` | Go | Dockerfile / `go` | Yes | NS |
| `src/currency` | C++ | Dockerfile / cmake | Yes | NS |
| `src/email` | Ruby | Dockerfile / bundler | Yes | NS |
| `src/flagd-ui` | Elixir | Dockerfile / mix | Yes | NS |
| `src/fraud-detection` | Kotlin | Gradle / Dockerfile | Yes | NS |
| `src/frontend` | TS/Next | Dockerfile / npm | Yes | NS |
| `src/frontend-proxy` | Envoy | Dockerfile | No | NS |
| `src/image-provider` | nginx | Dockerfile | No | NS |
| `src/kafka` | infra | Dockerfile | No | NS |
| `src/llm` | Python | Dockerfile | No | NS |
| `src/load-generator` | Python | Dockerfile | No | NS |
| `src/opensearch` | infra | Dockerfile | No | NS |
| `src/payment` | Node | Dockerfile / npm | Yes | NS |
| `src/product-catalog` | Go | Dockerfile / `go` | Yes | NS |
| `src/product-reviews` | Python | Dockerfile | Yes | NS |
| `src/quote` | PHP | Dockerfile | Yes | NS |
| `src/react-native-app` | TS/RN | npm / Gradle (Android) | Yes | NS |
| `src/recommendation` | Python | Dockerfile | Yes | NS |
| `src/shipping` | Rust | Dockerfile / cargo | Yes | NS |

Infra/config under `src/` (grafana, jaeger, prometheus, postgresql, otel-collector, flagd) are not listed above; track separately when image rules are introduced.
