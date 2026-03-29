# Bazel Concepts Primer for OpenTelemetry Demo Architecture

## 1) Why this document exists

This is a companion guide for `2-bazel-architecture-otel-shop-demo.md`.

Purpose:

- Explain Bazel and build-system concepts used in the architecture doc.
- Help a new Bazel learner read architecture decisions with confidence.
- Connect each concept to real examples in this monorepo (`src/`, `pb/`, `test/`).

If you read this first, the architecture document becomes much easier to understand.

---

## 2) Quick mental model: what Bazel is

Bazel is a **build and test engine** that treats your repository like a graph:

- Nodes = targets (libraries, binaries, tests, images, etc.)
- Edges = dependencies between targets

Instead of running scripts step-by-step manually, Bazel:

1. Analyzes the dependency graph.
2. Builds only what is needed.
3. Reuses cached outputs when inputs are unchanged.
4. Runs actions in a controlled environment for reproducibility.

In one sentence: Bazel turns builds into deterministic graph execution.

---

## 3) Core Bazel building blocks

## 3.1 `BUILD.bazel`

A `BUILD.bazel` file defines targets in a directory/package.

Think: "makefile fragment for one folder, but with strict target dependency declarations."

Typical targets:

- library target
- binary target
- test target
- image target

## 3.2 Target labels

A Bazel target is referenced like:

- `//src/checkout:checkout_bin`

Meaning:

- `//src/checkout` = package path
- `checkout_bin` = target name

## 3.3 Rules

A rule is a template for target types.

Examples across languages:

- Go rules create `go_library`, `go_binary`, `go_test`
- Python rules create Python lib/bin/test targets
- JVM rules create Java/Kotlin targets
- OCI/image rules create container image targets

Rules are what make Bazel polyglot.

## 3.4 Inputs and outputs

Each target has declared:

- Inputs: source files, deps, toolchains, config
- Outputs: compiled artifact, test result, image, generated code

Bazel can cache outputs safely because inputs are explicit.

---

## 4) Build system concepts you see in architecture doc 2

## 4.1 Dependency graph (DAG)

DAG = Directed Acyclic Graph.

- Directed: A depends on B has direction.
- Acyclic: no circular dependencies allowed.

Why it matters:

- enables safe parallelism
- avoids hidden coupling
- allows affected-target analysis

## 4.2 Hermetic build

Hermetic means build actions depend only on declared inputs.

No undeclared access to:

- random system binaries
- undeclared network resources
- local machine state

Why it matters:

- reproducible CI/local behavior
- cache correctness
- security and supply-chain confidence

## 4.3 Reproducibility

Reproducible build = same source + same config => same output.

This is critical for:

- release confidence
- artifact integrity
- debugging “works on my machine” issues

## 4.4 Incremental builds

Bazel rebuilds only impacted targets when files change.

In this repo, this means:

- touch one service -> only related targets rebuild
- no full monorepo rebuild unless necessary

## 4.5 Caching

Two major cache styles:

- Local cache: on developer machine/CI runner.
- Remote cache: shared cache service for team/CI.

Benefits:

- much faster repeat builds
- CI speed improvements on similar changes

## 4.6 Remote execution (advanced)

Actions execute on remote workers, not only local runner.

Useful when:

- large C++/JVM builds
- heavy parallel test workloads

Not required on day 1; usually after cache rollout.

---

## 5) Modern Bazel module/dependency concepts

## 5.1 `MODULE.bazel` (Bzlmod)

Bzlmod is Bazel’s modern dependency management system.

In architecture doc 2, this is why we centralize rule/toolchain versions there.

Benefits:

- clean, versioned module dependencies
- better upgrades
- less ad-hoc external-repo wiring

## 5.2 Locking and pinning

Pinning means exact versions are controlled.

Why:

- deterministic dependency resolution
- better security posture

In polyglot repos, pinning prevents "silent drift" between languages.

## 5.3 Toolchains

A toolchain tells Bazel which compiler/runtime/tool version to use.

Examples:

- Go compiler version
- Java runtime/toolchain
- Python interpreter constraints
- C++ compiler settings

This is how you standardize builds across laptops and CI.

---

## 6) Target categories used in the architecture

## 6.1 Library target

Reusable compiled code package.

- used by binaries/tests
- encourages modular design

## 6.2 Binary target

Executable/service artifact.

For this repo:

- service server binary/jar/package

## 6.3 Test target

Runnable test unit under Bazel.

Can represent:

- unit tests
- integration tests
- e2e tests
- trace validation tests

## 6.4 Image target (OCI)

Builds container image artifact from compiled outputs/config.

This is key to replacing ad-hoc Dockerfile matrix logic with graph-based image builds.

## 6.5 Push/publish target

CI-only target that uploads image/artifact to registry.

Often separated from build target for safer local workflows.

---

## 7) Test concepts used in doc 2

## 7.1 Test tagging

Tags are labels for test selection.

Common tags in architecture:

- `unit`
- `integration`
- `trace`
- `e2e`
- `slow`
- `manual`

Usage examples:

- fast PR run excludes `slow`, `manual`
- nightly includes broader sets

## 7.2 Test profiles

A profile is a reusable test selection strategy.

Examples:

- fast profile for PR checks
- full profile for merge gates
- release profile for strict release checks

## 7.3 Flaky test quarantine

When a test is unstable, isolate it temporarily via tag/profile rather than breaking all CI.

Important: quarantine is temporary; fix root cause ASAP.

---

## 8) CI/CD concepts used in doc 2

## 8.1 Affected-target CI

Given changed files, compute impacted targets and run only those.

Why:

- faster PR feedback
- less wasted CI time

## 8.2 Fast vs full pipelines

- Fast pipeline: essential checks, short feedback loop.
- Full pipeline: broader verification before merge/release.

Both use same Bazel graph, different target selection.

## 8.3 Pipeline orchestrator vs build engine

Important distinction:

- Orchestrator: GitHub Actions or Zuul (controls jobs/workflow)
- Build engine: Bazel (executes build/test graph)

In architecture doc 2, this is why migration to Zuul does not require changing build semantics.

---

## 9) Security and supply-chain concepts in doc 2

## 9.1 SBOM

Software Bill of Materials: list of components/dependencies in an artifact.

Used for:

- auditing
- vulnerability response
- compliance

## 9.2 Vulnerability gates

Pipeline policy that blocks artifacts above allowed severity threshold.

Typical policy:

- PR: block critical
- release: block high and critical

## 9.3 Provenance / attestation

Metadata proving:

- what was built
- from which source
- by which pipeline

Helps establish artifact trust chain.

## 9.4 Policy-as-code

Rules evaluated automatically in CI (instead of manual checks), for example:

- base image allowlist
- non-root container policy
- required labels
- license constraints

---

## 10) Polyglot build concepts (language-specific)

## 10.1 Go

Default world:

- `go.mod` + `go build` + `go test`

Bazel world:

- explicit go targets and deps
- shared proto integration through graph

Main gain:

- strict dependency declarations and robust incremental builds.

## 10.2 Node.js / TypeScript

Default world:

- package manager + scripts

Bazel world:

- lockfile-driven deps + explicit app/test/image targets

Main gain:

- reproducibility + consistent CI selection for lint/e2e/build.

## 10.3 Python

Default world:

- `requirements.txt` + runtime scripts

Bazel world:

- explicit Python targets + controlled dependencies and test execution

Main gain:

- less dependency drift and better cache behavior.

## 10.4 Java/Kotlin

Default world:

- Gradle tasks and wrapper

Bazel world:

- Bazel JVM targets (Gradle may remain transitional)

Main gain:

- monorepo graph consistency with other languages.

## 10.5 .NET

Default world:

- `dotnet restore/build/publish`

Bazel world:

- staged wrapper integration then deeper native adoption

Main gain:

- unified CI gating and artifact graph across ecosystems.

## 10.6 Rust

Default world:

- cargo build/test

Bazel world:

- crate targets integrated with same graph and image pipeline

Main gain:

- consistent monorepo dependency and CI treatment.

## 10.7 C++

Default world:

- CMake/make in Docker contexts

Bazel world:

- native C++ graph with toolchain control

Main gain:

- deterministic compiler settings and scalable caching.

## 10.8 Ruby / PHP / Elixir (pragmatic lane)

Default world:

- ecosystem-native build commands

Bazel world:

- often starts with wrapper strategy for hermetic orchestration, then evolves

Main gain:

- consistency with rest of platform while respecting ecosystem maturity.

---

## 11) Concepts behind architecture diagrams in doc 2

## 11.1 Layering

Why layers exist:

- enforce separation of concerns
- prevent accidental coupling

Pattern in doc 2:

- modules/toolchains -> shared macros -> proto/common -> services -> images -> CI/policy

## 11.2 State transition diagrams

Phase diagrams show migration maturity over time:

- not all services migrate at once
- each phase has exit criteria

## 11.3 Sequence diagrams

Used to model runtime order:

- developer command -> Bazel analysis -> toolchain usage -> artifact creation

Helps distinguish static architecture from execution flow.

---

## 12) How to read `2-bazel-architecture-otel-shop-demo.md` effectively

Recommended reading order:

1. Start with global architecture diagram.
2. Read repository layout and layering section.
3. Read execution flow diagrams (dev, CI, release).
4. Read language deep-dive section relevant to your immediate service lane.
5. Review command matrices.
6. Finish with risks and acceptance criteria.

When you encounter unfamiliar terms:

- map them back to sections 3-10 in this primer.

---

## 13) Glossary (quick lookup)

- **Action**: single executable step Bazel runs for a target.
- **Artifact**: output file/object produced by build/test/image action.
- **BEP**: Build Event Protocol output stream for build metadata.
- **Bzlmod**: modern Bazel dependency management via `MODULE.bazel`.
- **Cache hit**: Bazel reuses output because inputs match previous action.
- **Hermetic**: action uses only declared inputs/toolchain.
- **OCI image**: standard container image format.
- **Package**: Bazel directory scope containing a `BUILD.bazel`.
- **Rule**: target type definition template.
- **Stamping**: injecting build metadata (version/sha/time) into outputs.
- **Target**: addressable build/test/image unit (e.g., `//src/x:y`).
- **Toolchain**: compiler/runtime/tool version config Bazel uses.
- **Transitional wrapper**: Bazel target that orchestrates existing ecosystem build command during migration.

---

## 14) Practical starter learning path (for this repo)

1. Learn label syntax and target graph basics.
2. Understand `MODULE.bazel`, `.bazelrc`, `BUILD.bazel` roles.
3. Practice with one simple lane first (Go service recommended).
4. Add unit test target and run with tags.
5. Add image target for same service.
6. Understand affected-target CI concept.
7. Move to more complex lanes (frontend, JVM, .NET).

This mirrors the phased architecture and reduces overload.

---

## 15) Final bridge to the architecture doc

After this primer, the following concepts in `2-bazel-architecture-otel-shop-demo.md` should be clear:

- why the monorepo is modeled as layered target graphs
- why proto migration is an early phase
- why test tagging and profile separation are central
- why image build/publish targets are distinct
- why security gates are integrated into build architecture (not bolted on later)
- why GitHub Actions and Zuul can share the same Bazel command contracts

Use this primer as your concept dictionary while reading the architecture blueprint.

