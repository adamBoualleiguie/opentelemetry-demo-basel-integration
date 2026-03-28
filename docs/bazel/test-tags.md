# Bazel test tags (BZ-130)

This repo uses **tags** on `go_test`, and later `py_test` / `rust_test` / `js_test`, so CI and developers can filter **unit**, **integration**, **e2e**, and **trace**-heavy suites. Aligned with **`5-bazel-migration-task-backlog.md`** **BZ-130** and **`2-bazel-architecture-otel-shop-demo.md`** test taxonomy.

## `.bazelrc` configs (repo root)

| Config | Effect |
|--------|--------|
| `test:unit` | Runs tests tagged `unit`; excludes `integration`, `e2e`, `trace`, `slow`, `manual`. |
| `test:integration` | Runs `integration` tests; excludes `e2e`, `trace`, `slow`, `manual`. |
| `test:e2e` | Runs tests tagged `e2e`. |
| `test:trace` | Runs tests tagged `trace`. |

**Examples:**

```bash
bazel test //... --config=unit
bazel test //src/checkout/... --config=ci --config=unit
```

**Note:** With `--config=unit`, **only** tests that include the `unit` tag are executed. Untagged tests are **not** run. Use plain `bazel test //...` when you want every test regardless of tags.

## Tag meanings

| Tag | When to use |
|-----|-------------|
| `unit` | Fast, hermetic, no live Docker Compose dependency. Default for small package tests. |
| `integration` | Needs local services, databases, or Compose (may use `local` executor or `tags = ["manual"]` in CI). |
| `e2e` | Browser / full stack (e.g. Cypress, **BZ-131**). |
| `trace` | Tracetest or trace-validation suites (**BZ-132**). |
| `slow` | Large timeouts; optional exclusion from PR gates. |
| `manual` | Never run unless explicitly requested (`bazel test //target --test_tag_filters=manual`). |

## Rules for contributors

1. **Every new `go_test`** should set **`tags = ["unit"]`** unless it is clearly integration/e2e/trace (then use the appropriate tag, or `manual`).  
2. **Gazelle** does not add tags automatically; update **`BUILD.bazel`** after `gazelle update`.  
3. **Python / Rust / JS / Ruby / Elixir / PHP / React Native (`sh_test`)** tests: apply the same convention when those targets are added (**M3+**).

## Current `unit` tests

| Target | Tags |
|--------|------|
| `//src/checkout/money:money_test` | `unit` |
| `//src/shipping:shipping_test` | `unit` |
| `//src/currency:currency_proto_smoke_test` | `unit` |
| `//src/email:email_gems_smoke_test` | `unit` |
| `//src/flagd-ui:flagd_ui_mix_test` | `unit` |
| `//src/quote:quote_composer_smoke_test` | `unit` |
| `//src/react-native-app:rn_js_checks` | `unit` |
| `//src/frontend-proxy:frontend_proxy_config_test` | `unit` |
| `//src/image-provider:image_provider_config_test` | `unit` |

---

See also: **`docs/bazel/milestones/m3-completion.md`** § Epic N, **`.bazelrc`**.
