# Service Bazel migration tracker

Snapshot through **M3** frontend OCI + Python **`py_binary`** wave; playbook in **`docs/bazel/milestones/m3-completion.md`**. Update as milestones progress.

Legend: **NS** = Not started | **P** = Proto in Bazel | **B** = Build | **T** = Test | **I** = Image | **CI** = CI gated on Bazel for this service

| Path | Language | Build entrypoint (today) | Proto consumer | Bazel proto (M1) | Status |
|------|----------|---------------------------|----------------|------------------|--------|
| `src/accounting` | .NET | Dockerfile / `dotnet` | Yes | `//pb:demo.proto` → `src/protos` (Bazel) | B/I |
| `src/ad` | Java | Gradle / Dockerfile | Yes | `//pb:demo_java_grpc` | B/I |
| `src/cart` | .NET | Dockerfile / `dotnet` | Yes | `//pb:demo.proto` → **`pb/demo.proto`** in publish tree (Bazel) | B/I |
| `src/checkout` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_checkout` | B/T/I |
| `src/currency` | C++ | Dockerfile / cmake | Yes | `//pb:demo.proto` → genrule copy + `proto_library` in `//src/currency` (**BZ-092**); optional **`//pb:demo_cpp_grpc`** for other C++ consumers | B/T/I |
| `src/email` | Ruby | Dockerfile / bundler | Yes | — | B/T/I |
| `src/flagd-ui` | Elixir | Dockerfile / mix | Yes | — | B/T/I |
| `src/fraud-detection` | Kotlin | Gradle / Dockerfile | Yes | `//pb:demo_java_grpc` | B/I |
| `src/frontend` | TS/Next | Dockerfile / npm | Yes | — | B/T/I |
| `src/frontend-proxy` | Envoy | Dockerfile | No | — | NS |
| `src/image-provider` | nginx | Dockerfile | No | — | NS |
| `src/kafka` | infra | Dockerfile | No | — | NS |
| `src/llm` | Python | Dockerfile | No | — | B/I |
| `src/load-generator` | Python | Dockerfile | No | — | B/I |
| `src/opensearch` | infra | Dockerfile | No | — | NS |
| `src/payment` | Node | Dockerfile / npm | Yes | — | B/I |
| `src/product-catalog` | Go | Dockerfile / `go` | Yes | `//pb:demo_go_proto_product_catalog` | B/T |
| `src/product-reviews` | Python | Dockerfile | Yes | `//pb:demo_py_grpc` | B/I |
| `src/quote` | PHP | Dockerfile / Composer | Yes | — | B/T/I |
| `src/react-native-app` | TS/RN (Expo) | npm / Gradle (**Android only** in Bazel) | Yes | — | B/T |
| `src/recommendation` | Python | Dockerfile | Yes | `//pb:demo_py_grpc` | B |
| `src/shipping` | Rust | Dockerfile / cargo | Yes | — (proto in Bazel TBD) | B/T/I |

**Shared:** `pb/demo.proto` → `//pb:demo_proto` (all RPC services in one file).

**CI:** `.github/workflows/checks.yml` job **`bazel_smoke`** (`continue-on-error: true`) builds **`//src/checkout/...`**, **`//src/product-catalog/...`**, **`//src/payment/...`** (includes **`payment_image`**), **`//src/frontend:frontend_image`**, **`//pb:demo_py_grpc`**, **`//pb:demo_java_grpc`**, **`//src/ad:ad`**, **`//src/ad:ad_oci_image`**, **`//src/fraud-detection:fraud_detection`**, **`//src/fraud-detection:fraud_detection_oci_image`**, **`//src/accounting:accounting_publish`**, **`//src/accounting:accounting_image`**, **`//src/cart:cart_publish`**, **`//src/cart:cart_image`** (**.NET 10** via **`actions/setup-dotnet`**), **`//src/shipping:shipping`**, **`//src/shipping:shipping_image`**, **`//src/currency:currency`**, **`//src/currency:currency_image`**, **`//src/email:email`**, **`//src/email:email_image`**, **`//src/flagd-ui:flagd_ui_publish`**, **`//src/flagd-ui:flagd_ui_image`**, **`//src/quote:quote_publish`**, **`//src/quote:quote_image`** (**PHP 8.4** + **Composer** via **`shivammathur/setup-php`**), the four Python **`py_binary`** targets and their **`*_image`** targets, runs Go tests for the two Go services, **`bazel test //src/shipping/...`**, **`bazel test //src/currency:currency_proto_smoke_test`**, **`bazel test //src/email:email_gems_smoke_test`**, **`bazel test //src/flagd-ui:flagd_ui_mix_test`**, **`bazel test //src/quote:quote_composer_smoke_test`**, **`bazel test //src/react-native-app:rn_js_checks`** (**Node 22** — **`tsc`** + **`jest`**; **Android APK** build is **`manual`**, not in default smoke), and runs **`bazel test //src/frontend:lint`** (**BZ-051**).

Infra/config under `src/` (grafana, jaeger, prometheus, postgresql, otel-collector, flagd) are not listed above; track separately when image rules are introduced.

**M3 (majority services + images):** see **`docs/bazel/milestones/m3-completion.md`** and **`docs/bazel/oci-policy.md`** (BZ-120). **BZ-121:** **`checkout`**, **`payment`**, **`frontend`**, Python **`recommendation`**, **`product-reviews`**, **`llm`**, **`load-generator`**, JVM **`ad`**, **`fraud-detection`**, **.NET `accounting`**, **.NET `cart`**, **Rust `shipping`**, **C++ `currency`**, **Ruby `email`**, **Elixir `flagd-ui`**, and **PHP `quote`** each have **`oci_image`** (+ **`oci_load`** where defined); **`next_build`** / some frontend prep remain **`manual`** where tagged.

**BZ-130 (test tags):** **`docs/bazel/test-tags.md`**; **`bazel test //... --config=unit`** runs only tests tagged **`unit`** (**`//src/checkout/money:money_test`**, **`//src/shipping:shipping_test`**, **`//src/flagd-ui:flagd_ui_mix_test`**, **`//src/quote:quote_composer_smoke_test`**, **`//src/react-native-app:rn_js_checks`**, …). **`cart`** **`dotnet test`** is not wired as **`bazel test`** yet (**BZ-081**).
