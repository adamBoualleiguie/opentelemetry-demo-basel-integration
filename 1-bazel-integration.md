# Bazel Integration Blueprint for OpenTelemetry Astronomy Shop Fork

## 1) Goal and positioning

This document is a practical, production-grade plan to migrate this polyglot monorepo from a Docker Compose + language-native build approach to a Bazel-first build and test architecture.

Target outcomes:

- Deterministic and cacheable builds/tests across all services.
- Fast incremental CI with reliable affected-target selection.
- Better supply-chain security controls (provenance, pinned dependencies, policy checks).
- Progressive adoption that keeps the demo running while migration is in flight.
- A CI model that works first in GitHub Actions and can later be gated by Zuul.

This plan is intentionally phased from basic to advanced so you can demonstrate both delivery pragmatism and high-end Bazel architecture decisions.

---

## 2) Current-state baseline (before Bazel)

## 2.1 Repository orchestration model today

The current build/test orchestration is Make + Docker Compose centric:

- `Makefile` is the top-level entrypoint for build/lint/test/protobuf generation.
- `docker-compose.yml` and `docker-compose.minimal.yml` orchestrate local runtime.
- `docker-compose-tests.yml` orchestrates test containers.
- `docker-gen-proto.sh` and `ide-gen-proto.sh` generate protobuf outputs.

Primary commands in active use:

- Build and run: `make build`, `make start`, `make stop`.
- Tests: `make run-tests`, `make run-tracetesting`.
- Protobuf generation: `make docker-generate-protobuf`, `make generate-protobuf`.
- Quality gates: `make misspell`, `make markdownlint`, `make checklicense`, `yamllint`.

## 2.2 CI/CD model today (GitHub Actions)

Key workflows:

- `.github/workflows/checks.yml`:
  - Reuses `component-build-images.yml` for image build matrix.
  - Runs markdown/yaml/spell/link/license/sanity checks.
- `.github/workflows/component-build-images.yml`:
  - Reusable workflow building multi-arch images for nearly all services.
  - Includes protobuf cleanliness gate (`make clean docker-generate-protobuf` + clean tree check).
- `.github/workflows/run-integration-tests.yml`:
  - Runs on PR review approval.
  - Executes `make build && docker system prune -f && make run-tracetesting`.
- Release pipelines:
  - `release.yml` and `nightly-release.yml` call reusable image workflow.

Observations:

- CI is container-build heavy, not target-graph aware.
- Change detection is mostly directory diff logic around Dockerfile paths.
- Testing focus is trace-based integration; unit test execution is not centralized.

## 2.3 Polyglot technology surface

The repo contains services and components in:

- Go (`checkout`, `product-catalog`)
- .NET (`accounting`, `cart`)
- Java (`ad`)
- Kotlin (`fraud-detection`)
- Node.js / TypeScript (`frontend`, `payment`, `react-native-app`)
- Python (`recommendation`, `product-reviews`, `load-generator`, `llm`)
- Rust (`shipping`)
- C++ (`currency`)
- Ruby (`email`)
- Elixir (`flagd-ui`)
- PHP (`quote`)
- Infra containers/config components (`frontend-proxy`, `kafka`, `opensearch`, `image-provider`, `postgresql`, `jaeger`, `grafana`, `prometheus`, `otel-collector`, etc.)

## 2.4 Why this is ideal for Bazel

You can clearly show value in a real monorepo with:

- Multi-language dependency resolution under one build graph.
- Better incremental behavior than all-or-nothing docker compose builds.
- Unified test execution API (`bazel test //...` subsets by tags/scope).
- Shared remote cache and optional remote execution.
- First-class reproducibility and provenance pipelines.

---

## 3) Target architecture with Bazel

## 3.1 Principles

1. Keep runtime deployment model stable first (Docker Compose / Kubernetes unchanged at start).
2. Move build/test/proto generation under Bazel progressively.
3. Keep existing Make targets as a compatibility facade during migration.
4. Standardize dependency pinning and hermetic toolchains via Bzlmod.
5. Introduce strictness only after green baseline (warnings -> errors phased).

## 3.2 High-level end state

- Root Bazel workspace with `MODULE.bazel` (Bzlmod enabled).
- Per-service `BUILD.bazel` with language-appropriate rules.
- Central protobuf module and generated outputs as Bazel targets (no committed generated drift needed long-term).
- OCI image build standardized with Bazel image rules.
- Tests grouped and tagged (`unit`, `integration`, `e2e`, `trace`, `slow`, `manual`) for selective CI.
- GitHub Actions uses Bazelisk + remote cache.
- Security checks integrated into Bazel/CI path (SBOM, vulnerability scan, policy check, provenance).

---

## 4) Phased migration plan (basic -> advanced)

## Phase 0 - Discovery freeze and migration guardrails

Deliverables:

- Inventory of all current build/test entrypoints (already mapped).
- Migration tracker table for each service (status, owner, Bazel target parity).
- Definition of done for each service:
  - Builds via Bazel.
  - Tests executable via Bazel (if tests exist).
  - Container image can be produced via Bazel.
  - Existing runtime behavior unchanged.

Actions:

1. Create `docs/` migration notes or keep this as single source until split.
2. Declare branch strategy:
   - `main` for normal work.
   - `feat/bazel-bootstrap`.
   - Short-lived service migration branches.
3. Set performance baseline before migration:
   - Current `make build` duration.
   - Current integration test duration.
   - CI median duration for checks workflow.

## Phase 1 - Bazel bootstrap (non-invasive)

Objective: introduce Bazel tooling with zero service rewrites.

Actions:

1. Add Bazel bootstrap files:
   - `MODULE.bazel`
   - `.bazelrc`
   - `.bazelversion` (for Bazelisk pinning)
   - Optional `tools/bazel/` for shared macros.
2. Configure common repo settings:
   - Strict action environment defaults.
   - Build event protocol output settings.
   - Test output format defaults.
3. Add initial utility targets:
   - `//:format_check`
   - `//:license_check`
   - `//:markdownlint`
   - `//:yamllint`
   These can wrap existing tools initially, then become native Bazel actions.
4. Add dev bootstrap docs:
   - Install Bazelisk.
   - Use `bazelisk test //...` and `bazelisk build //...`.

Success criteria:

- Bazel commands run in repo.
- No existing Make/CI flows broken.
- Team can execute at least a small Bazel target set locally and in CI.

## Phase 2 - Protobuf pipeline migration first

Objective: move protobuf generation/consumption into Bazel graph early.

Why first:

- Protobuf currently spans multiple languages and is a shared pain point.
- It gives immediate graph-level correctness and cache wins.

Actions:

1. Create proto package:
   - `pb/BUILD.bazel` with `proto_library` targets.
2. Introduce language-specific proto generation targets:
   - Go, Python, TS, C++, Java/Kotlin, C# where applicable.
3. Replace `make clean docker-generate-protobuf` CI gate with Bazel proto validation target.
4. Decide generated artifact strategy:
   - Preferred long-term: generated code not committed, consumed via Bazel outputs.
   - Transitional: keep committed generated code while Bazel targets verify no drift.

Success criteria:

- CI protobuf consistency check runs through Bazel.
- At least 3 language consumers compile against Bazel-generated proto outputs.

## Phase 3 - Language lane migration (service build/test parity)

Objective: onboard services incrementally by language family.

Recommended order (risk-balanced):

1. Go services (`checkout`, `product-catalog`) - usually smooth with Bazel rules.
2. Node services (`payment`, then `frontend`) - JS ecosystem is manageable with lockfiles and pnpm/npm strategy.
3. Python services (`recommendation`, `product-reviews`, `llm`, `load-generator`).
4. Java/Kotlin (`ad`, `fraud-detection`).
5. .NET (`accounting`, `cart`).
6. Rust (`shipping`).
7. C++ (`currency`).
8. Ruby (`email`), PHP (`quote`), Elixir (`flagd-ui`) as advanced lanes.

Per-service migration checklist:

1. Add `BUILD.bazel` in service directory.
2. Model source + deps + compile target.
3. Add test targets if tests exist.
4. Add OCI image target (see Phase 4).
5. Validate parity:
   - Existing Dockerfile-based build output behavior.
   - Runtime env vars and ports.
   - Health endpoints.

Success criteria:

- Each migrated service has `bazel build` + `bazel test` parity proof.
- No regressions in compose-based runtime.

## Phase 4 - OCI image standardization via Bazel

Objective: migrate image build matrix from direct Dockerfile orchestration to Bazel-controlled image graph.

Actions:

1. Introduce image rules (OCI-focused) in Bazel modules.
2. For each migrated service:
   - Build binary/artifact in Bazel.
   - Assemble image in Bazel (layers, entrypoint, env).
3. Keep ability to consume legacy Dockerfiles during transition where needed.
4. Add multi-arch strategy:
   - Build by platform transitions.
   - Publish tags with consistent naming.

Success criteria:

- `component-build-images.yml` can call Bazel targets for a subset of services.
- Artifact tags match current naming conventions to avoid downstream breakage.

## Phase 5 - CI migration to Bazel-first

Objective: shift GitHub Actions from script matrix to target graph execution.

Actions:

1. Add Bazel setup job template:
   - Bazelisk install.
   - Cache wiring (repo cache + disk cache + optional remote cache).
2. Convert checks:
   - markdownlint/yamllint/license/sanity -> Bazel targets.
3. Convert build images:
   - matrix by Bazel target groups, not Dockerfile path logic.
4. Add affected-target optimization:
   - derive changed files and query impacted Bazel targets.
5. Keep fallback path to legacy make/docker jobs until confidence threshold reached.

Success criteria:

- CI runtime reduced measurably.
- False-positive rebuilds reduced.
- CI logic simplified around Bazel target semantics.

## Phase 6 - Advanced optimization and governance

Objective: use advanced Bazel capabilities for scale, reliability, security.

Actions:

1. Remote cache (shared, authenticated, branch-aware keys).
2. Optional remote execution for heavy targets.
3. Configurable build profiles:
   - `--config=ci`, `--config=release`, `--config=dev`.
4. Test sharding and flaky test quarantine tags.
5. Policy-as-code checks integrated as Bazel test targets.
6. Build metadata + BEP ingestion for observability dashboards.

Success criteria:

- Stable p95 CI times.
- High cache hit rate in PR workflows.
- Clear policy compliance posture in every pipeline.

---

## 5) Suggested Bazel module/rule strategy (latest architecture style)

Use Bzlmod-first design (`MODULE.bazel`) with explicit versions and minimal ad-hoc repository rules.

Recommended rule families (verify exact versions at implementation time):

- Core:
  - Bazel Skylib
  - Platform/toolchain utilities
- Language rules:
  - Go rules
  - Java/Kotlin rules
  - Node/JS/TS rules
  - Python rules
  - Rust rules
  - C++ native toolchain setup
  - .NET, Ruby, PHP, Elixir: evaluate maturity and choose pragmatic wrappers where native Bazel support is limited.
- Proto/GRPC:
  - Proto rule stack + language adapters.
- Container/image:
  - OCI-oriented rules for image assembly and publish.
- Security:
  - Targets wrapping SBOM and vulnerability scanners.

Design note for resume/interview impact:

- For ecosystems with weaker Bazel-native support (Ruby/PHP/Elixir/.NET in some contexts), use a hybrid approach:
  - Bazel `genrule` / custom rules to orchestrate hermetic containerized builds.
  - Keep deterministic inputs and explicit outputs.
  - Move to richer native rules only when ROI is clear.

This shows practical engineering, not dogmatism.

---

## 6) Directory and target modeling blueprint

Proposed structure:

- `MODULE.bazel`
- `.bazelrc`
- `tools/bazel/` (macros, shared defs, CI helpers)
- `pb/BUILD.bazel`
- `src/<service>/BUILD.bazel` per service
- `test/tracetesting/BUILD.bazel`

Target naming conventions:

- `:<service>_lib` for reusable library code.
- `:<service>_bin` for executable/service runtime.
- `:<service>_unit_tests`
- `:<service>_image`
- `:<service>_push` (publish target, CI-only)

Tagging conventions:

- `tags = ["unit"]`, `["integration"]`, `["e2e"]`, `["trace"]`, `["manual"]`, `["slow"]`
- CI selection examples:
  - Fast PR: exclude `manual`, `slow`, `trace`.
  - Merge/release: include all non-manual.

---

## 7) Progressive GitHub Actions design (Bazel-first)

## Stage A - Add parallel Bazel signal (non-blocking)

In `checks.yml`:

- Keep current jobs.
- Add non-blocking `bazel_smoke` job:
  - `bazelisk build //pb:all`
  - `bazelisk test //...` on small allowlist.

## Stage B - Replace lint/sanity with Bazel targets

- `markdownlint`, `yamllint`, `checklicense`, `sanity` become Bazel invocations.
- Remove duplicate script logic from workflows where possible.

## Stage C - Build images through Bazel for migrated services

- In reusable `component-build-images.yml`, add Bazel path:
  - Build/publish Bazel OCI targets for migrated services.
  - Keep Dockerfile matrix for unmigrated services.

## Stage D - Affected-target CI

- Compute changed files.
- Use Bazel query/analysis script to derive impacted targets.
- Run only affected build/test/image targets in PR checks.

## Stage E - Full Bazel gating + release

- All primary build/test/image/publish paths through Bazel.
- Legacy make/docker paths retained only for emergency fallback.

---

## 8) Security and supply-chain plan (must-have for senior interview impact)

## 8.1 Dependency and provenance controls

1. Pin toolchain and rule versions in `MODULE.bazel`.
2. Lock external dependency resolution outputs where supported.
3. Generate provenance attestations for release artifacts.
4. Sign/publish images with verifiable metadata.

## 8.2 SBOM and vulnerability scanning

1. Generate SBOM per image artifact during CI (SPDX or CycloneDX).
2. Scan images and dependencies in PR and release contexts.
3. Define severity policy gates:
   - PR: fail on critical.
   - Release: fail on high/critical unless explicit waiver.

## 8.3 Policy as code

Add policy checks as Bazel targets for:

- Disallowed base images.
- Required image labels.
- Non-root container execution.
- Forbidden network calls in build actions (hermeticity guardrails).
- License policy compliance.

## 8.4 Secrets and credential posture

- Keep registry creds in GitHub secrets / OIDC-based short-lived tokens.
- Avoid long-lived static credentials in CI.
- Separate permissions per workflow:
  - read-only for checks,
  - package write only for publish jobs.

## 8.5 Integrity and reproducibility

- Reproducibility checks for selected release targets.
- Build stamping only where needed (avoid cache busting by default).
- Artifact digest promotion model (deploy by digest, not mutable tags).

---

## 9) Future Zuul gated integration design

When adding Zuul as a gate, keep Bazel as single build/test engine and swap orchestrator.

## 9.1 Strategy

1. Mirror GitHub checks logic in Zuul jobs using Bazel commands.
2. Use Zuul pipelines:
   - `check`: affected-target fast path.
   - `gate`: full required tests for merge.
   - `promote`/`release`: signed publish path.
3. Share scripts:
   - Keep command wrappers in repo (`tools/ci/*.sh`) so GitHub and Zuul execute same logic.

## 9.2 Recommended Zuul job layers

- `bazel-lint`
- `bazel-unit`
- `bazel-integration-trace`
- `bazel-image-build`
- `bazel-image-security-scan`
- `bazel-release-publish` (restricted, protected branch/tags only)

## 9.3 Gating policies

- Required for merge:
  - lint + unit + impacted integration.
- Required for protected branches:
  - full integration + image build + vulnerability gate.
- Required for release:
  - full matrix + signed attestation + SBOM + policy checks.

This is the key message: CI platform can change, but Bazel target graph and rule contracts remain the stable foundation.

---

## 10) Practical migration map by component in this repo

## 10.1 Services likely easiest first

- `src/checkout` (Go)
- `src/product-catalog` (Go)
- `src/payment` (Node)
- `src/recommendation` (Python)

These give fast early wins and good demo material.

## 10.2 Mid-complexity

- `src/frontend` (Next.js + Cypress)
- `src/ad` (Gradle Java)
- `src/fraud-detection` (Kotlin/Gradle)
- `src/shipping` (Rust)
- `src/accounting`, `src/cart` (.NET)

## 10.3 Advanced/edge migrations

- `src/currency` (C++)
- `src/flagd-ui` (Elixir)
- `src/email` (Ruby)
- `src/quote` (PHP)
- infra-like components with config-heavy behavior (`frontend-proxy`, `kafka`, `opensearch`, etc.)

For advanced lanes, use transitional custom rules or hermetic containerized actions through Bazel to preserve consistency.

---

## 11) Compatibility strategy with existing Make workflows

During migration, keep developer UX stable:

- `make build` can delegate to Bazel for migrated targets.
- `make run-tracetesting` stays valid while test runtime remains compose-driven.
- Introduce parallel Bazel commands in docs before flipping defaults.

Recommended progression:

1. Add `make bazel-build`, `make bazel-test`.
2. Announce optional usage period.
3. Flip internal CI first.
4. Flip default make targets only after confidence threshold and team sign-off.

---

## 12) KPIs to prove Bazel value (for Volvo interview narrative)

Track before/after and present hard numbers:

1. PR CI median duration.
2. p95 CI duration.
3. Cache hit ratio.
4. Average number of services rebuilt per PR.
5. Integration test duration delta.
6. Failure reproducibility rate (local vs CI parity).
7. Security gate coverage (SBOM %, signed artifact %, policy pass rate).

In interviews, this differentiates "tool installation" from "platform engineering impact."

---

## 13) Risks and mitigations

1. Polyglot rule maturity varies.
   - Mitigation: hybrid Bazel orchestration with incremental native adoption.
2. Team learning curve.
   - Mitigation: service templates, macro libraries, clear docs, office-hours pairing.
3. CI complexity during dual-run period.
   - Mitigation: strict sunset milestones, avoid permanent dual pipelines.
4. Cache poisoning / non-hermetic actions.
   - Mitigation: lock down action env, ban undeclared inputs, enforce reproducibility checks.
5. Flaky integration tests.
   - Mitigation: tagging, retries only for known flakes, isolate infra vs app flakes.

---

## 14) 30/60/90-day execution plan

## First 30 days

- Bazel bootstrap files and conventions.
- Proto pipeline under Bazel.
- 2-4 low-risk services migrated (Go/Node/Python mix).
- Non-blocking Bazel CI job.

## Day 31-60

- Expand to frontend + JVM lane + Rust/.NET pilot.
- Bazel-based lint/sanity checks become default in checks workflow.
- First Bazel-built OCI images in CI publish path.
- Remote cache enabled for CI.

## Day 61-90

- Majority service coverage in Bazel build/test.
- Release path primarily Bazel-driven.
- Security stack integrated (SBOM, scan, attestation gates).
- Zuul job blueprint validated in parallel (or PoC if infra available).

---

## 15) Example command model after migration

Developer commands:

- Build all: `bazelisk build //...`
- Test fast set: `bazelisk test //... --test_tag_filters=-slow,-manual,-trace`
- Test integration trace suite: `bazelisk test //test/tracetesting:all`
- Build one service image: `bazelisk build //src/checkout:checkout_image`

CI commands:

- Affected build/test:
  - `bazelisk query` based impacted targets
  - `bazelisk test <impacted targets>`
- Release image publish:
  - `bazelisk run //src/<service>:<service>_push`

---

## 16) What improves versus current state

Current model strengths:

- Very approachable local run with Docker Compose.
- Clear service-level Dockerfiles.

Current model limitations:

- Limited graph-aware incrementalism.
- Build/test logic spread across Make, Dockerfiles, workflow YAML, and language tools.
- Hard to standardize policy/security gates consistently across all languages.

Bazel-led improvements:

- One dependency/build/test graph across polyglot services.
- Better selective execution and cache reuse.
- Cleaner CI abstraction and easier portability to Zuul.
- Stronger reproducibility and supply-chain controls.

---

## 17) Recommended immediate next steps in this fork

1. Create bootstrap Bazel files (`MODULE.bazel`, `.bazelrc`, `.bazelversion`).
2. Implement proto targets in `pb/BUILD.bazel`.
3. Migrate first 2 services (`checkout`, `product-catalog`) as showcase.
4. Add non-blocking Bazel job in `.github/workflows/checks.yml`.
5. Add metrics capture script for build/test timing baseline.

This path gives quick visible wins and sets up a strong technical story for your Bazel-focused opportunity.

