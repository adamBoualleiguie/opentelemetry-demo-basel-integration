# M0 completion report — Bazel bootstrap

This document records **what was implemented** for milestone **M0** from `5-bazel-migration-task-backlog.md`:

> **M0:** Bazel runs in the repo; CI has a **non-blocking** Bazel smoke job.

**Global summary:** The repository is now a **Bazel (Bzlmod) workspace** with a trivial build target (`//:smoke`), **Make-backed lint entrypoints** exposed as `sh_binary` targets for `bazel run`, a **`tools/bazel/`** skeleton, **governance docs** under `docs/bazel/`, and a **`bazel_smoke` job** in GitHub Actions (`continue-on-error: true` so the rest of Checks stays the merge gate). No application services were migrated yet; Docker Compose and the existing Makefile remain the source of truth for builds and checks.

---

## Prerequisites (for local `bazel run //:lint`)

The lint wrappers delegate to the **same** commands as the Makefile:

- **Node.js 20+** (LTS). Node 16 fails on current `markdownlint-cli` / `string-width` (regex `v` flag). CI uses Node 20.
- **npm** at repo root (`npm install`).
- **Python 3** + **yamllint** (`make install-yamllint` installs it if missing).
- **Go** (for `make misspell` / `make checklicense`, which compile tools under `internal/tools`).

Pure Bazel verification without those tools:

```bash
bazelisk build //:smoke --config=ci
bazelisk query //...
```

---

## Per-task completion (backlog IDs)

### Epic A — Program setup and baselines

| ID | Task | Status | What was done |
|----|------|--------|----------------|
| **BZ-001** | Migration charter and branch strategy | Done | Added `docs/bazel/charter.md` (purpose, branch naming `feat/bazel-*`, per-service definition of done, placeholder owners table). |
| **BZ-002** | Service inventory and tracker | Done | Added `docs/bazel/service-tracker.md` with all major `src/*` services, primary language, today’s build entrypoint, proto flag, status **NS** (Not started). |
| **BZ-003** | Performance and CI baselines | Done | Added `docs/bazel/baselines.md` with measurement instructions and **TBD** tables to fill on your machine/CI (local `make build`, trace tests, `bazelisk build //:smoke`, `bazelisk run //:lint`). |
| **BZ-004** | Risk register | Done | Added `docs/bazel/risk-register.md` with risks R1–R6 (rule maturity, dual pipeline, cache, flakes, onboarding, non-hermetic lint wrappers) and mitigations. |

### Epic B — Workspace bootstrap

| ID | Task | Status | What was done |
|----|------|--------|----------------|
| **BZ-010** | `.bazelversion` + Bazelisk | Done | Created `.bazelversion` pinning **Bazel 7.4.1** (matches `bazelisk version` resolution). Contributors should use [Bazelisk](https://github.com/bazelbuild/bazelisk). |
| **BZ-011** | `MODULE.bazel` (Bzlmod) | Done | Added root `MODULE.bazel` with `module(name = "otel_demo", version = "0.0.0")`. No external `bazel_dep` yet (M1+ will add rules_proto, rules_go, etc.). |
| **BZ-012** | Root `BUILD.bazel` + smoke | Done | Root `BUILD.bazel` defines `genrule` **`//:smoke`** → `bazel-bin/smoke.txt` with content marker `bazel-m0-smoke-ok`. Verified: `bazelisk build //:smoke --config=ci`. |
| **BZ-013** | `.bazelrc` profiles | Done | Added `.bazelrc`: `common --enable_bzlmod`; `build:dev`, `build:ci`, `build:release`, `build:integration` placeholders; `test:ci --test_output=errors`. CI smoke uses `--config=ci`. |
| **BZ-014** | `.bazelignore` | Done | Added `.bazelignore` for `.git`, `node_modules`, Bazel symlinks, RN/Pods, `.venv`, `src/shipping/target`, `.gradle`, `.next`, `out`. Speeds `query` / analysis. |
| **BZ-015** | `tools/bazel/` skeleton | Done | Created `tools/bazel/defs/`, `ci/`, `platforms/` with README placeholders; lint scripts under `tools/bazel/lint/*.sh`. Matches structure in `2-bazel-architecture-otel-shop-demo.md`. |
| **BZ-016** | Buildifier / style convention | Done | Added `docs/bazel/build-style.md` (Buildifier recommendation, Bzlmod preference, license header note). No CI enforcement yet. |

### Epic C — Repo hygiene targets in Bazel

| ID | Task | Status | What was done |
|----|------|--------|----------------|
| **BZ-020** | `//:markdownlint` | Done | `sh_binary` running `make markdownlint` from repo root (`tools/bazel/lint/markdownlint.sh`). **Use:** `bazel run //:markdownlint` (requires `BUILD_WORKSPACE_DIRECTORY`; set automatically by `bazel run`). |
| **BZ-021** | `//:yamllint` | Done | `sh_binary` → `make yamllint` (`tools/bazel/lint/yamllint.sh`). |
| **BZ-022** | `//:misspell` and `//:checklicense` | Done | `sh_binary` targets → `make misspell` / `make checklicense`. |
| **BZ-023** | `//:sanitycheck` | Done | `sh_binary` → `python3 internal/tools/sanitycheck.py`. |
| **BZ-024** | Meta `//:lint` | Done | `sh_binary` **`//:lint`** runs, in order: `markdownlint`, `yamllint`, `misspell`, `checklicense`, `sanitycheck` (`tools/bazel/lint/lint_all.sh`). **Use:** `bazel run //:lint`. |

**Design note (M0):** These targets are **intentionally not hermetic**: they shell out to Make and host tools so behavior stays **identical** to existing automation. Later milestones can replace them with native Bazel actions (`rules_nodejs`, etc.) for cache and hermeticity.

### Epic O — CI (M0 slice)

| ID | Task | Status | What was done |
|----|------|--------|----------------|
| **BZ-610** | GitHub Actions Bazel smoke | Done | In `.github/workflows/checks.yml`, added job **`bazel_smoke`**: checkout; **Go**; **Node 20**; **Python**; `npm install`; `make install-yamllint`; **setup-bazelisk**; `bazelisk version`; `bazelisk build //:smoke --config=ci`; `bazelisk run //:lint`. Job has **`continue-on-error: true`** (non-blocking). **`build-test`** now **needs** `bazel_smoke` so the job runs before the aggregate result (failed bazel job still yields success for dependency purposes when continue-on-error applies). |

---

## Files added or changed (inventory)

| Path | Action |
|------|--------|
| `.bazelversion` | Added |
| `MODULE.bazel` | Added |
| `MODULE.bazel.lock` | Added (Bazel-generated lockfile) |
| `.bazelrc` | Added |
| `.bazelignore` | Added |
| `BUILD.bazel` | Added (root package) |
| `tools/bazel/lint/*.sh` | Added (executable wrappers) |
| `tools/bazel/defs/README.md` | Added |
| `tools/bazel/ci/README.md` | Added |
| `tools/bazel/platforms/README.md` | Added |
| `docs/bazel/charter.md` | Added |
| `docs/bazel/service-tracker.md` | Added |
| `docs/bazel/baselines.md` | Added |
| `docs/bazel/risk-register.md` | Added |
| `docs/bazel/build-style.md` | Added |
| `docs/bazel/m0-completion.md` | Added (this file) |
| `.github/workflows/checks.yml` | Updated (`bazel_smoke`, `build-test` needs) |
| `.gitignore` | Updated (`/bazel-*`) |

---

## Commands reference (after M0)

```bash
# Verify workspace
bazelisk version
bazelisk build //:smoke --config=ci
bazelisk query //...

# Lint parity with Makefile (host tools required; Node 20+)
bazelisk run //:markdownlint
bazelisk run //:lint
```

---

## Verification performed in this fork

- `bazelisk build //:smoke --config=ci` — **success**
- `bazelisk query //...` — lists `//:smoke`, `//:lint`, and individual lint binaries
- `bazelisk run //:lint` — **requires Node 20+**; on Node 16, `markdownlint` fails with a `SyntaxError` in a dependency (environment issue, not Bazel graph issue)

---

## Next steps (M1 preview)

1. Add **`bazel_dep`** for **rules_proto** / **rules_go** (and lock `pb/` with `proto_library`).
2. Replace protobuf CI gate (`make clean docker-generate-protobuf`) with a Bazel check (per backlog BZ-030–038).
3. Migrate **`src/checkout`** and **`src/product-catalog`** (BZ-040–041).

---

## Related documents

| Document | Role |
|----------|------|
| `5-bazel-migration-task-backlog.md` | Full task IDs and milestones |
| `2-bazel-architecture-otel-shop-demo.md` | Target layout and diagrams |
| `4-bazel-dev-environment-ubuntu.md` | Host toolchain checklist |
| `docs/bazel/charter.md` | Migration charter |

---

*M0 closed: Bazel workspace operational; CI smoke wired; governance and tracker in place. Proceed to M1 (proto graph).*
