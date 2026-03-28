# Bazel migration — full task backlog (implementation plan)

## 1) Purpose and scope

This is **document 5** in the series. It is an **ordered, actionable backlog** to take this fork from **Make + Docker Compose + per-language builds** to **Bazel as the primary build and test system**, without implementing anything in this step.

**Companion documents:**

| Doc | Role |
|-----|------|
| `1-bazel-integration.md` | Strategy, phases, value, CI/security direction |
| `2-bazel-architecture-otel-shop-demo.md` | Target layout, diagrams, per-service mapping |
| `3-bazel-concepts-for-otel-architecture.md` | Concepts glossary for readers |
| `4-bazel-dev-environment-ubuntu.md` | Host tooling (you indicated env is ready) |

**Assumptions for this backlog:**

- Host toolchains (Go, Rust, Node, Python, JVM, .NET, etc.) are available per `4-bazel-dev-environment-ubuntu.md` where needed during migration; Bazel-managed toolchains can replace or complement them over time.
- **No code changes** are performed while authoring this document; tasks below are **for future implementation**.

**How to use this backlog:**

- Execute tasks **in epic order** unless dependencies say otherwise.
- Use task IDs (e.g. `BZ-010`) in commits and PR titles for traceability.
- Mark each task **Done** only when its **acceptance criteria** are met.

---

## 2) Program milestones (high level)

| Milestone | Meaning |
|-----------|---------|
| **M0** | Bazel runs in repo; CI has non-blocking Bazel smoke. |
| **M1** | Proto graph in Bazel; CI protobuf gate uses Bazel (or dual-run). |
| **M2** | First language wave (Go + one more) fully buildable/testable in Bazel. |
| **M3** | Majority of application services build in Bazel; images for migrated services via Bazel. |
| **M4** | CI default path is Bazel-first (build/test); Docker matrix reduced or delegated. |
| **M5** | Release path Bazel-first; security gates (SBOM/scan/policy) wired. |
| **M6** | Make/legacy paths deprecated or thin wrappers; optional Zuul job parity documented. |

---

## 3) Task ID legend

- **BZ-0xx** — Program setup, governance, baselines  
- **BZ-1xx** — Workspace bootstrap  
- **BZ-2xx** — Proto / codegen  
- **BZ-3xx** — Per-language / per-service migration  
- **BZ-4xx** — OCI images and artifacts  
- **BZ-5xx** — Tests (unit, e2e, trace)  
- **BZ-6xx** — CI/CD (GitHub Actions, scripts)  
- **BZ-7xx** — Security, supply chain, policy  
- **BZ-8xx** — Documentation, developer UX, cutover  
- **BZ-9xx** — Hardening, optional RE/cache, Zuul, cleanup  

---

## 4) Epic A — Program setup and baselines (M0 prep)

### BZ-001 — Migration charter and branch strategy

- **Description:** Document owners, communication channel, branch naming (`feat/bazel-*`), merge policy, and “definition of done” per service (align with `1-bazel-integration.md` §Phase 0).
- **Acceptance criteria:** Written charter (can live in `docs/` or section in README); branch strategy agreed.
- **Depends on:** —  
- **Milestone:** M0  

### BZ-002 — Service inventory and tracker

- **Description:** Maintain a table: every `src/<service>`, language, current build entrypoint (Dockerfile, Gradle, npm, etc.), test entrypoints, proto consumer yes/no, migration status (Not started / Proto only / Build / Test / Image / CI).
- **Acceptance criteria:** Tracker file in repo; matches current tree; updated when tasks complete.
- **Depends on:** BZ-001  
- **Milestone:** M0  

### BZ-003 — Performance and CI baselines

- **Description:** Record: local `make build` time (cold/warm), `make run-tracetesting` duration, GitHub Actions `checks` typical duration; note runner type.
- **Acceptance criteria:** Baseline numbers stored (e.g. in tracker or `docs/`); method documented.
- **Depends on:** BZ-001  
- **Milestone:** M0  

### BZ-004 — Risk register

- **Description:** List risks (rule maturity per language, dual pipeline maintenance, cache poisoning, flaky trace tests, contributor onboarding); mitigations and owners.
- **Acceptance criteria:** Risk register file; reviewed before M2.
- **Depends on:** BZ-001  
- **Milestone:** M0  

---

## 5) Epic B — Workspace bootstrap (M0)

### BZ-010 — Add `.bazelversion` and Bazelisk contract

- **Description:** Pin Bazel version; document “install Bazelisk” in contributor-facing doc.
- **Acceptance criteria:** `.bazelversion` present; `bazelisk version` works from repo root.
- **Depends on:** —  
- **Milestone:** M0  

### BZ-011 — Add `MODULE.bazel` (Bzlmod)

- **Description:** Create empty/minimal module; declare name/version; plan module deps (skylib, rules for languages as they are added).
- **Acceptance criteria:** `bazelisk build` or `bazelisk query //...` succeeds on a trivial target after BZ-012.
- **Depends on:** BZ-010  
- **Milestone:** M0  

### BZ-012 — Root `BUILD.bazel` and no-op or smoke target

- **Description:** e.g. `//:empty` or filegroup; proves workspace loads.
- **Acceptance criteria:** `bazelisk build //:all` or documented smoke target passes.
- **Depends on:** BZ-011  
- **Milestone:** M0  

### BZ-013 — `.bazelrc` profiles

- **Description:** Add `--config=ci`, `--config=dev` (and placeholders for `release`, `integration`) per `2-bazel-architecture-otel-shop-demo.md` §5.2; document flags (test output, disk cache, strictness).
- **Acceptance criteria:** Profiles documented; CI uses `--config=ci` in at least one job (BZ-610).
- **Depends on:** BZ-011  
- **Milestone:** M0  

### BZ-014 — `.bazelignore`

- **Description:** Exclude `node_modules`, `.git`, large vendored dirs, IDE artifacts, so analysis stays fast.
- **Acceptance criteria:** `bazelisk query //...` does not traverse ignored trees incorrectly; documented.
- **Depends on:** BZ-011  
- **Milestone:** M0  

### BZ-015 — `tools/bazel/` skeleton

- **Description:** Create `tools/bazel/defs/`, `tools/bazel/ci/`, `tools/bazel/platforms/` (empty or README) per architecture doc.
- **Acceptance criteria:** Directory layout matches `2-bazel-architecture-otel-shop-demo.md` §4.1.
- **Depends on:** BZ-012  
- **Milestone:** M0  

### BZ-016 — Optional: Buildifier / buildozer convention

- **Description:** Document or script formatting for `BUILD`/`bzl` files; optional pre-commit.
- **Acceptance criteria:** CONTRIBUTING or dev doc mentions standard; optional CI check stub.
- **Depends on:** BZ-015  
- **Milestone:** M0  

---

## 6) Epic C — Repo hygiene targets in Bazel (M0)

*These can wrap existing scripts first; native actions later.*

### BZ-020 — `//:markdownlint` (or package)

- **Description:** Run root markdownlint equivalent to `make markdownlint` (may invoke npm via rules or genrule with documented constraints).
- **Acceptance criteria:** `bazelisk run` or `bazelisk test` target exists; results match Make on sample run.
- **Depends on:** BZ-012, root `package.json`  
- **Milestone:** M0  

### BZ-021 — `//:yamllint`

- **Description:** Yamllint over repo (respect exclusions if needed).
- **Acceptance criteria:** Target passes when repo is clean; documented Python/yamllint assumption or hermetic venv.
- **Depends on:** BZ-012  
- **Milestone:** M0  

### BZ-022 — `//:misspell` and `//:checklicense`

- **Description:** Align with `Makefile` misspell and addlicense checks (Go tools under `internal/tools`).
- **Acceptance criteria:** Bazel targets reproduce Make behavior for same inputs.
- **Depends on:** BZ-012  
- **Milestone:** M0  

### BZ-023 — `//:sanitycheck`

- **Description:** Wrap `internal/tools/sanitycheck.py`.
- **Acceptance criteria:** CI-equivalent pass/fail.
- **Depends on:** BZ-012  
- **Milestone:** M0  

### BZ-024 — Meta-target `//:lint`

- **Description:** Single target or test suite aggregating BZ-020–023.
- **Acceptance criteria:** One command documented for “all repo lint gates.”
- **Depends on:** BZ-020–023  
- **Milestone:** M0  

---

## 7) Epic D — Protobuf and codegen (M1)

### BZ-030 — `pb/BUILD.bazel`: `proto_library` for `demo.proto`

- **Description:** Central `proto_library` (and any dependencies) for `pb/demo.proto`.
- **Acceptance criteria:** `bazelisk build //pb:...` succeeds; proto is single source of truth.
- **Depends on:** BZ-011  
- **Milestone:** M1  

### BZ-031 — Go proto/gRPC codegen targets

- **Description:** Targets consumed by `checkout` and `product-catalog` (replace or mirror `genproto` layout).
- **Acceptance criteria:** Go services compile against Bazel-generated Go protos (in-tree or in `bazel-out`).
- **Depends on:** BZ-030, rules_proto / rules_go wiring  
- **Milestone:** M1  

### BZ-032 — Python grpc codegen targets

- **Description:** For `recommendation`, `product-reviews`, etc., per current `docker-gen-proto.sh` / `ide-gen-proto.sh` consumers.
- **Acceptance criteria:** At least one Python service uses Bazel-generated `_pb2` outputs in build.
- **Depends on:** BZ-030  
- **Milestone:** M1  

### BZ-033 — TypeScript / Node proto targets (`ts_proto`)

- **Description:** For `frontend` (and `react-native-app` if in scope), align with `protoc-gen-ts_proto` options used today.
- **Acceptance criteria:** Frontend build path can depend on generated TS under Bazel.
- **Depends on:** BZ-030  
- **Milestone:** M1  

### BZ-034 — Java / Kotlin proto targets (for `ad`, `fraud-detection`)

- **Description:** gRPC Java/Kotlin generation from same `proto_library`.
- **Acceptance criteria:** JVM services can depend on generated sources via Bazel.
- **Depends on:** BZ-030  
- **Milestone:** M1  

### BZ-035 — C++ proto targets (`currency`)

- **Description:** Align with OpenTelemetry C++ / gRPC codegen used in Docker genproto path.
- **Acceptance criteria:** `currency` compiles with Bazel-generated C++ protos (or documented hybrid).
- **Depends on:** BZ-030  
- **Milestone:** M1  

### BZ-036 — .NET proto targets (`accounting`, `cart`)

- **Description:** C# generation from `demo.proto` per service layout.
- **Acceptance criteria:** .NET projects consume Bazel-generated protos or verified sync with committed output.
- **Depends on:** BZ-030  
- **Milestone:** M1  

### BZ-037 — Proto drift / regeneration policy

- **Description:** Decide: (A) stop committing generated code and use Bazel outputs only, or (B) keep committed gen + `bazel test //pb:check_no_drift`. Implement chosen policy.
- **Acceptance criteria:** Documented policy; CI enforces it (BZ-630).
- **Depends on:** BZ-031–036 (as applicable)  
- **Milestone:** M1  

### BZ-038 — Deprecate or dual-run protobuf CI gate

- **Description:** Today: `make clean docker-generate-protobuf` + `make check-clean-work-tree` in `component-build-images.yml`. Add Bazel equivalent; run in parallel then switch.
- **Acceptance criteria:** CI fails on proto drift via Bazel; transition plan documented.
- **Depends on:** BZ-037, BZ-630  
- **Milestone:** M1  

---

## 8) Epic E — Language wave 1: Go (M2)

### BZ-040 — `src/checkout`: `BUILD.bazel`, library/binary, tests

- **Description:** `go_library`, `go_binary`, `go_test` for existing tests; deps on BZ-031.
- **Acceptance criteria:** `bazelisk build //src/checkout/...` and `bazelisk test //src/checkout/...` pass.
- **Depends on:** BZ-031  
- **Milestone:** M2  

### BZ-041 — `src/product-catalog`: same as BZ-040

- **Acceptance criteria:** Same as BZ-040 for product-catalog.
- **Depends on:** BZ-031  
- **Milestone:** M2  

### BZ-042 — Go toolchain strategy document

- **Description:** Document Bazel-managed Go SDK vs host `go`; MODULE pins.
- **Acceptance criteria:** Doc updated in `4-*` or new dev doc; CI uses same version.
- **Depends on:** BZ-040  
- **Milestone:** M2  

---

## 9) Epic F — Language wave 2: Node (M2–M3)

### BZ-050 — `src/payment`: npm lockfile, `BUILD.bazel`, binary/runtime target

- **Description:** rules_js (or chosen stack) for `payment`; test target if applicable.
- **Acceptance criteria:** `bazelisk build` produces runnable artifact; parity with Dockerfile behavior documented.
- **Depends on:** BZ-011 (js rules), optional BZ-033 if protos used  
- **Milestone:** M2  

### BZ-051 — `src/frontend`: Next.js app target, lint target

- **Description:** Build and lint under Bazel; document Next.js + Bazel caveats (output dirs, env).
- **Acceptance criteria:** `bazelisk build` for frontend succeeds; `bazelisk test` for lint if modeled as test.
- **Depends on:** BZ-033, js rules  
- **Milestone:** M3  

### BZ-052 — `src/react-native-app` (optional / phased)

- **Description:** JS bundle + tests under Bazel first; Android/iOS native via wrapper or later phase.
- **Acceptance criteria:** Documented scope; minimal Bazel target set if included in M3.
- **Depends on:** BZ-051  
- **Milestone:** M3 (optional)  

---

## 10) Epic G — Language wave 3: Python (M3)

### BZ-060 — Pin Python requirements strategy (per service)

- **Description:** requirements lock or pip-tools; Bazel Python rules consumption pattern.
- **Acceptance criteria:** One service (`recommendation` or `product-reviews`) fully buildable in Bazel.
- **Depends on:** BZ-032, python rules  
- **Milestone:** M3  

### BZ-061 — `src/recommendation`, `src/product-reviews`, `src/llm`, `src/load-generator`

- **Description:** Repeat pattern; `load-generator` may be `py_binary` for Locust.
- **Acceptance criteria:** Each listed service has `bazel build` target; tests where they exist.
- **Depends on:** BZ-060  
- **Milestone:** M3  

---

## 11) Epic H — JVM: Java and Kotlin (M3)

### BZ-070 — `src/ad`: Bazel Java targets (or wrapper → migrate)

- **Description:** Prefer native `java_binary` / `java_library`; transitional `genrule` calling `./gradlew` only if needed.
- **Acceptance criteria:** Artifact equivalent to Gradle `installDist` or Docker build stage.
- **Depends on:** BZ-034, java rules  
- **Milestone:** M3  

### BZ-071 — `src/fraud-detection`: Kotlin / JVM fat jar equivalent

- **Description:** Shadow JAR or equivalent output for image.
- **Acceptance criteria:** Binary/jar buildable via Bazel.
- **Depends on:** BZ-034, kotlin rules  
- **Milestone:** M3  

---

## 12) Epic I — .NET (M3–M4)

### BZ-080 — `src/accounting` Bazel targets

- **Description:** rules_dotnet or hermetic wrapper invoking `dotnet publish` with declared outputs.
- **Acceptance criteria:** Publish output suitable for OCI layer assembly.
- **Depends on:** BZ-036 or proto policy  
- **Milestone:** M3  

### BZ-081 — `src/cart` Bazel targets + tests

- **Description:** Include xUnit tests when no longer skipped; tag `unit`.
- **Acceptance criteria:** `bazelisk test //src/cart/...` runs tests or documents skip policy.
- **Depends on:** BZ-080 pattern  
- **Milestone:** M4  

---

## 13) Epic J — Rust (M3–M4)

### BZ-090 — `src/shipping`: `rust_library` / `rust_binary`, tests

- **Description:** rules_rust; Cargo.toml integration; proto if applicable.
- **Acceptance criteria:** `bazelisk build` + `bazelisk test` for shipping.
- **Depends on:** rules_rust, BZ-030 if protos required  
- **Milestone:** M3  

---

## 14) Epic K — C++, Ruby, PHP, Elixir (M4)

### BZ-100 — `src/currency` C++ Bazel build

- **Description:** `cc_binary` or cmake rule integration; link grpc/otel as today.
- **Acceptance criteria:** Binary matches Dockerfile behavior at functional level.
- **Depends on:** BZ-035  
- **Milestone:** M4  

### BZ-101 — `src/email` Ruby wrapper or native rules

- **Description:** Hermetic bundle + image inputs; document limitations.
- **Acceptance criteria:** Runnable artifact via Bazel-defined outputs.
- **Depends on:** —  
- **Milestone:** M4  

### BZ-102 — `src/quote` PHP/Composer wrapper or rules

- **Acceptance criteria:** Same as BZ-101 for quote.
- **Depends on:** —  
- **Milestone:** M4  

### BZ-103 — `src/flagd-ui` Elixir/Mix release via Bazel

- **Acceptance criteria:** Release tarball or equivalent for OCI; tests wired with tags.
- **Depends on:** BZ-034  
- **Milestone:** M4  

---

## 15) Epic L — Infra / config-only images (M4)

### BZ-110 — Map non-app services under `src/` (`frontend-proxy`, `image-provider`, `kafka`, `opensearch`, etc.)

- **Description:** For each: `filegroup` + OCI assembly target or Dockerfile passthrough rule; document pattern in `tools/bazel/defs/service_image.bzl`.
- **Acceptance criteria:** Each image either Bazel-built or explicitly “wrapper only” with ticket to migrate.
- **Depends on:** BZ-120 (image macros)  
- **Milestone:** M4  

---

## 16) Epic M — OCI images and artifacts (M3–M4)

### BZ-120 — Choose OCI rule stack and base image policy

- **Description:** Select rules for image build/push; define allowed base images (for BZ-720).
- **Acceptance criteria:** ADR or doc; one pilot image built with Bazel (BZ-121).
- **Depends on:** BZ-040 or BZ-050 (pilot service)  
- **Milestone:** M3  

### BZ-121 — Pilot: one service image end-to-end (`checkout` or `payment`)

- **Description:** `//src/<svc>:<svc>_image` loadable in Docker; tag naming documented.
- **Acceptance criteria:** `docker load` or registry push from CI dry-run.
- **Depends on:** BZ-120  
- **Milestone:** M3  

### BZ-122 — Roll out image targets per migrated service

- **Description:** Align tags with `component-build-images.yml` naming (`version-suffix`, `latest-suffix`).
- **Acceptance criteria:** Matrix table in BZ-002 updated per service.
- **Depends on:** BZ-121, per-service epics  
- **Milestone:** M4  

### BZ-123 — `push` targets and CI secrets model

- **Description:** Separate `*_push` from local `*_image`; document GHCR/Docker Hub tokens.
- **Acceptance criteria:** Release workflow can invoke push targets only on tag/main policy.
- **Depends on:** BZ-122, BZ-630  
- **Milestone:** M4  

---

## 17) Epic N — Tests: tags, Cypress, Tracetest (M3–M5)

### BZ-130 — Global test tag convention

- **Description:** Implement `unit`, `integration`, `trace`, `e2e`, `slow`, `manual` per `2-bazel-architecture-otel-shop-demo.md`.
- **Acceptance criteria:** Documented in CONTRIBUTING; `.bazelrc` examples for filters.
- **Depends on:** BZ-013  
- **Milestone:** M3  

### BZ-131 — Wrap or replace Cypress as Bazel test (`frontend`)

- **Description:** Target that runs Cypress in sandbox-friendly way (may be `tags = manual` initially).
- **Acceptance criteria:** `bazelisk test //src/frontend:e2e` (or similar) documented.
- **Depends on:** BZ-051  
- **Milestone:** M4  

### BZ-132 — Tracetest suite as Bazel test or `sh_test` driver

- **Description:** Orchestrate `test/tracetesting` against compose or test stack; align with `make run-tracetesting`.
- **Acceptance criteria:** CI can invoke trace tests via Bazel or documented hybrid until full migration.
- **Depends on:** BZ-130  
- **Milestone:** M5  

### BZ-133 — Consolidate language unit tests under `bazel test`

- **Description:** Go, Rust, Elixir, .NET, etc., all discoverable with tag filters.
- **Acceptance criteria:** `bazelisk test //... --test_tag_filters=unit` runs all unit tests.
- **Depends on:** Per-service tasks  
- **Milestone:** M5  

---

## 18) Epic O — CI/CD: GitHub Actions (M4–M5)

### BZ-610 — Add Bazelisk setup to `checks.yml` (smoke job)

- **Description:** Non-blocking job: `bazelisk build //...` subset + `bazelisk test //:lint` or equivalent.
- **Acceptance criteria:** Green on `main`; does not remove existing jobs.
- **Depends on:** BZ-012, BZ-024  
- **Milestone:** M0–M1  

### BZ-611 — `tools/bazel/ci/ci_fast.sh` and `ci_full.sh`

- **Description:** Scripts invoked by GitHub Actions and (later) Zuul; same commands, different orchestrator.
- **Acceptance criteria:** Scripts documented; runnable locally.
- **Depends on:** BZ-015, BZ-024, affected-target script  
- **Milestone:** M4  

### BZ-612 — `tools/bazel/ci/affected_targets.sh`

- **Description:** Map `git diff` to `bazel query` / `bazel cquery` impacted targets; handle edge cases (BUILD changes, pb changes).
- **Acceptance criteria:** Documented inputs/outputs; used in PR workflow.
- **Depends on:** BZ-611  
- **Milestone:** M4  

### BZ-613 — PR workflow: fast path with cache

- **Description:** GitHub Actions cache for disk cache or remote cache credentials (read-only for PRs).
- **Acceptance criteria:** Measurable improvement vs cold build; documented in BZ-003 comparison.
- **Depends on:** BZ-612  
- **Milestone:** M4  

### BZ-630 — Replace or dual-run protobuf gate (see BZ-038)

- **Acceptance criteria:** Bazel gate required on PR.
- **Depends on:** BZ-038  
- **Milestone:** M1  

### BZ-631 — `component-build-images.yml`: Bazel matrix for migrated services

- **Description:** For each migrated service, build/push via Bazel instead of Dockerfile matrix row; keep Dockerfile for others.
- **Acceptance criteria:** At least N services on Bazel path; matrix documented in BZ-002.
- **Depends on:** BZ-122, BZ-123  
- **Milestone:** M4  

### BZ-632 — `run-integration-tests.yml`: optional Bazel prelude

- **Description:** Ensure images used by compose are built with Bazel before `make run-tracetesting`, or document image pull strategy.
- **Acceptance criteria:** Integration workflow still passes; uses Bazel-built images when flag enabled.
- **Depends on:** BZ-131, BZ-132  
- **Milestone:** M5  

### BZ-633 — Release / nightly workflows call Bazel push targets

- **Description:** `release.yml`, `nightly-release.yml` integration.
- **Acceptance criteria:** Tagged releases publish Bazel-built images.
- **Depends on:** BZ-123  
- **Milestone:** M5  

---

## 19) Epic P — Security and supply chain (M5)

### BZ-720 — Base image allowlist and label policy

- **Description:** Policy target or script; fail CI on disallowed FROM.
- **Acceptance criteria:** Documented list; enforced on Bazel image targets.
- **Depends on:** BZ-120  
- **Milestone:** M5  

### BZ-721 — SBOM generation per published image

- **Description:** Integrate syft/cyclonedx or org standard; attach to release artifacts.
- **Acceptance criteria:** SBOM artifact for each release image.
- **Depends on:** BZ-123  
- **Milestone:** M5  

### BZ-722 — Vulnerability scan gate

- **Description:** Grype/Trivy or org tool; thresholds per branch (PR vs release).
- **Acceptance criteria:** CI fails per agreed policy; waivers documented.
- **Depends on:** BZ-721  
- **Milestone:** M5  

### BZ-723 — Provenance / attestation (optional org requirement)

- **Description:** SLSA-style provenance for release builds.
- **Acceptance criteria:** Attestation stored with images or in GH artifacts.
- **Depends on:** BZ-633  
- **Milestone:** M5  

---

## 20) Epic Q — Remote cache and optional RBE (M5–M6)

### BZ-800 — Remote cache endpoint and authentication

- **Description:** Bazel `--remote_cache=` with read for PRs, read/write for main; credential handling.
- **Acceptance criteria:** Documented `.bazelrc` user override; CI uses secrets.
- **Depends on:** BZ-613  
- **Milestone:** M5  

### BZ-801 — Optional: remote execution pool

- **Description:** Evaluate BuildBarn/Buildfarm or vendor solution for heavy C++/JVM.
- **Acceptance criteria:** Decision doc; PoC or defer with rationale.
- **Depends on:** BZ-800  
- **Milestone:** M6  

---

## 21) Epic R — Documentation, Make facade, cutover (M5–M6)

### BZ-810 — Developer onboarding: “Bazel quickstart”

- **Description:** Update or add doc: clone, Bazelisk, common commands, IDE notes (gopls/rust-analyzer vs Bazel).
- **Acceptance criteria:** New contributor can build/test first Go service from doc alone.
- **Depends on:** BZ-040  
- **Milestone:** M2  

### BZ-811 — Makefile thin wrappers

- **Description:** `make bazel-build`, `make bazel-test`, optional redirect of `make build` behind flag.
- **Acceptance criteria:** Documented; no surprise breakage for existing users.
- **Depends on:** Milestone M4 scope agreed  
- **Milestone:** M5  

### BZ-812 — Deprecation schedule for `docker-gen-proto.sh` / `ide-gen-proto.sh`

- **Description:** After BZ-038, mark scripts legacy; document migration path.
- **Acceptance criteria:** README/CONTRIBUTING notice; sunset date.
- **Depends on:** BZ-038  
- **Milestone:** M5  

### BZ-813 — Zuul job blueprint (documentation only until infra exists)

- **Description:** Map `ci_fast` / `ci_full` / `ci_release` to Zuul pipelines per `1-bazel-integration.md`.
- **Acceptance criteria:** Doc with job names, required projects, secrets, approximate timeouts.
- **Depends on:** BZ-611  
- **Milestone:** M6  

### BZ-814 — Final retrospective and metrics

- **Description:** Compare BZ-003 baselines to post-M5 metrics; update risk register.
- **Acceptance criteria:** Written retrospective; tracker 100% or explicit exceptions listed.
- **Depends on:** M5 achieved  
- **Milestone:** M6  

---

## 22) Suggested implementation order (summary checklist)

Use this as the **default sequence** when picking up work:

1. BZ-001 → BZ-004 (governance + tracker + baselines + risks)  
2. BZ-010 → BZ-016 (workspace bootstrap)  
3. BZ-020 → BZ-024 (lint in Bazel)  
4. BZ-610 (CI smoke)  
5. BZ-030 → BZ-038 (proto graph + CI gate migration)  
6. BZ-040 → BZ-041 (Go wave)  
7. BZ-120 → BZ-121 (first OCI image)  
8. BZ-050 → BZ-051 (Node wave + frontend)  
9. BZ-060 → BZ-061 (Python)  
10. BZ-070 → BZ-071 (JVM)  
11. BZ-090 (Rust)  
12. BZ-080 → BZ-081 (.NET)  
13. BZ-100 → BZ-103 (C++/Ruby/PHP/Elixir)  
14. BZ-110 (infra images)  
15. BZ-122 → BZ-123 (full OCI rollout + push)  
16. BZ-130 → BZ-133 (test taxonomy + e2e + trace)  
17. BZ-611 → BZ-633 (CI scripts + affected + release)  
18. BZ-720 → BZ-723 (security)  
19. BZ-800 → BZ-801 (cache / RBE)  
20. BZ-810 → BZ-814 (docs, Make cutover, Zuul doc, retro)  

Parallel tracks are possible after **BZ-030** (proto): e.g. Go (BZ-040) and payment (BZ-050) in parallel by different owners.

---

## 23) Definition of Done — whole program

The migration is **complete** when:

1. **BZ-002** tracker shows every application service at **Build + Test + Image** (or explicit waiver with reason).  
2. **CI default** for PRs runs **Bazel fast path** (BZ-613) and required lint/proto/unit gates pass.  
3. **Release** publishes images built via Bazel (BZ-633).  
4. **Proto** policy is single-path (BZ-037) and enforced in CI (BZ-038).  
5. **Security** minimum: SBOM + scan on release images (BZ-721–722); provenance if required (BZ-723).  
6. **Documentation**: contributors can follow BZ-810; legacy scripts sunset or documented (BZ-812).  
7. **Metrics**: BZ-814 shows improvement or explains trade-offs.  

---

## 24) Out of scope (unless explicitly added later)

- Changing upstream OpenTelemetry demo product behavior or telemetry semantics.  
- Replacing Docker Compose with Kubernetes for local dev (Helm/K8s stay as today unless a separate epic is opened).  
- Owning corporate Zuul infrastructure (BZ-813 is blueprint only).  
- Mobile store submission pipelines for `react-native-app`.  

---

*End of backlog — ready for implementation tracking (issues/Projects) without modifying application code in this step.*
