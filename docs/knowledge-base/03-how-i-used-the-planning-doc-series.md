# 03 — Planning the migration and laying the workspace foundation (Bzlmod)

[Chapter 02](./02-what-this-repo-was-before-bazel.md) showed how the Astronomy Shop ran **before** Bazel: Make, Compose, Dockerfiles, many native toolchains. This chapter answers two big questions in one place:

1. **How did I plan** the move to Bazel without losing my mind?  
2. **What is the first “real” Bazel machinery** — `MODULE.bazel`, lockfile, extensions — that everything else stands on?

I write it so you can read **only this knowledge base** and still understand the program. No “go open another document” — I **bring the definitions here**.

![](https://knowledge-base.local/screenshots/03-planning-whiteboard.png)

---

## Part A — Why plan at all?

A polyglot monorepo is not a weekend hack. If you start by randomly adding `BUILD.bazel` files, you get:

- half the services in Bazel and half in Docker-only land, with **no shared story** for protos or images;  
- CI that is **slower** than before because you run **both** worlds with no off-ramp;  
- reviewers who cannot tell **what “done” means** for a service.

**Planning** here means:

- a **spine** of milestones (M0, M1, …) so each slice has a clear finish line;  
- **task IDs** so commits and PRs stay traceable;  
- **acceptance criteria** so “I think it works” becomes “this command passes.”

```mermaid
flowchart TB
  subgraph bad [Without a spine]
    R1[Random BUILD files]
    R2[Broken CI]
    R3[Unclear done]
    R1 --> R2 --> R3
  end
  subgraph good [With a spine]
    P[Milestones + tasks]
    I[Implement slice]
    V[Verify commands]
    P --> I --> V
    V --> P
  end
```

---

## The five planning “layers” I kept in my head

Before touching code, I worked through **five kinds of thinking**. They match the numbered strategy write-ups at the **repo root** (integration blueprint, architecture, concepts, dev environment, task backlog). You do not need those filenames to learn this — here is what each **layer is for**:

| Layer | Purpose in plain words |
|-------|-------------------------|
| **1 — Why Bazel** | Value, risks, phased adoption: *what problem are we solving?* |
| **2 — Target shape** | Where files live: `pb/`, `src/<service>/`, `tools/bazel/`, CI layout. |
| **3 — Vocabulary** | Workspace, package, target, action, hermeticity — same words as the Bazel docs. |
| **4 — Machine setup** | Ubuntu (or CI) toolchains: Go, Node, JVM, .NET, … so builds are reproducible. |
| **5 — Work breakdown** | Ordered tasks with IDs, dependencies, and milestone tags. |

```mermaid
flowchart LR
  W[Why] --> S[Shape]
  S --> V[Vocabulary]
  V --> E[Environment]
  E --> T[Tasks]
  T --> I[Implementation]
```

Think of it as **zoom levels**: motivation → map → dictionary → laptop → checklist.

---

## Program milestones — full definitions (M0 → M6)

These are the **program-level** checkpoints. I treat them as the backbone; individual tasks hang off them.

| Milestone | What “done” means (simple) |
|-----------|----------------------------|
| **M0** | Bazel **runs** in the repo: you can `bazel build` at least a smoke target, CI has a **Bazel job** (at first it can be non-blocking), lint/docs can be wrapped as `bazel run` if you want parity with Make. |
| **M1** | **Protobufs** live in the Bazel graph: `proto_library` and language outputs (Go, Java, …) are built by Bazel; CI cares about proto **cleanliness** using Bazel (or dual-runs with the old scripts until trust is there). |
| **M2** | **First real wave**: at least one language path is **fully** buildable and testable in Bazel end-to-end (in this project: Go services + confidence the model works). |
| **M3** | **Most application services** build in Bazel; **container images** for migrated services exist as Bazel `oci_image` (or equivalent) targets — the big expansion across Python, Node, JVM, .NET, Rust, Ruby, Elixir, PHP, proxies, etc. |
| **M4** | **CI is Bazel-first** for the agreed graph: merge requests block on `bazel build` / `bazel test` scripts; Docker image matrix may remain for registry multi-arch, but **authority** shifts to Bazel for the migrated set. |
| **M5** | **Release and supply chain**: optional `oci_push`, SBOM / vulnerability scan hooks, base-image **policy** (allowlists), remote cache docs, developer shortcuts (Make targets), unit-test graph consolidation. |
| **M6** | **Legacy thinning**: Make/Compose stay for runtime, but “how we build” is clearly Bazel; optional extras (remote execution, other CI systems) documented — future work. |

```mermaid
flowchart LR
  M0[M0 bootstrap] --> M1[M1 protos]
  M1 --> M2[M2 first wave]
  M2 --> M3[M3 most services]
  M3 --> M4[M4 CI boss]
  M4 --> M5[M5 release/security]
  M5 --> M6[M6 polish]
```

**Continuity with chapter 02:** M0–M2 happen **while** Compose still owns `make start`. M3–M4 add **parallel** truth in Bazel. M5+ harden **shipping and policy**.

---

## Task IDs (BZ-xxx) — what the numbers mean

Work is grouped by **hundreds** so you can tell what kind of task it is from the ID:

| Range | Theme |
|-------|--------|
| **BZ-0xx** | Program setup: charter, service inventory, baselines, risk list |
| **BZ-1xx** | Workspace bootstrap: Bazel version, `MODULE.bazel`, smoke target, `.bazelrc`, `.bazelignore`, `tools/bazel/` layout |
| **BZ-2xx** | Proto / codegen |
| **BZ-3xx** | Per-language or per-service migration |
| **BZ-4xx** | OCI images and artifacts |
| **BZ-5xx** | Tests (unit, e2e, trace) |
| **BZ-6xx** | CI/CD scripts and workflows |
| **BZ-7xx** | Security and policy (SBOM, scan, allowlists) |
| **BZ-8xx** | Docs, developer UX, quickstarts, Make wrappers |
| **BZ-9xx** | Hardening, optional RBE, cleanup |

**How I use IDs in real life:**

- Put **`BZ-123`** in a commit message or PR title when it closes that slice.  
- When someone asks “why does this exist?” six months later, **search the ID** in the repo.

---

## Epics — batches of work (conceptual map)

Tasks are grouped into **epics** (big chapters). You do not need to memorize every epic name; you need the **idea**:

- **Program / governance** — charter, tracker table for each service, “how fast is CI?” baselines, risk register.  
- **Workspace bootstrap** — Bazel can load, trivial build works, configs exist.  
- **Hygiene in Bazel** — markdownlint, yamllint, license, sanity: often **wrapping** existing Make behavior first.  
- **Protobuf epic** — one source of truth under `pb/`, generated code consumed by services.  
- **Per-service migration** — repeated pattern: library → binary → test → image.  
- **CI epic** — scripts that run the **same** graph locally and on GitHub; cache; later “affected targets” hints.  
- **Security epic** — pinned bases, allowlists, SBOM, scans on release paths.

```mermaid
flowchart TB
  subgraph epics [Epic flow — simplified]
    G[Governance]
    W[Workspace]
    H[Hygiene targets]
    P[Protos]
    S[Services loop]
    C[CI]
    X[Security]
    G --> W --> H --> P --> S
    S --> C
    C --> X
  end
```

---

## How I planned one slice of work (repeatable recipe)

This is the loop I actually ran; it stays the same whether the milestone is “smoke target” or “PHP service + image”.

1. **Pick a milestone slice** — e.g. “M3 — quote service builds and has an image.”  
2. **Find tasks** that belong to that slice (by theme: proto consumer? OCI? tests?).  
3. **Read acceptance criteria** — what command must pass? what files must exist?  
4. **Check dependencies** — do I need protos or another library target first?  
5. **Implement** `BUILD.bazel` (+ small `tools/bazel/*.bzl` helpers if the rule set is ugly).  
6. **Verify** locally with the same commands CI will use.  
7. **Write down** what changed: service row status, commands, odd env vars — so future me does not rely on memory.

```mermaid
flowchart TD
  S1[Pick slice] --> S2[Find tasks + deps]
  S2 --> S3[Acceptance criteria]
  S3 --> S4[Implement BUILD.bazel]
  S4 --> S5[bazel build / test]
  S5 --> S6[Record notes]
```

**Acceptance criteria** sounds corporate; it is really just **“the proof”**: e.g. `bazel build //src/quote:quote_image` exits 0.

---

## Dependencies between tasks (DAG thinking before Bazel DAG)

Tasks say **depends on** other tasks. Example pattern: you cannot claim a Go service is “done in Bazel” if **`MODULE.bazel` does not declare `rules_go`** and `//pb:...` does not build.

```mermaid
flowchart TD
  BZ011[Module + deps] --> BZ012[Smoke BUILD]
  BZ012 --> BZ030[Proto targets]
  BZ030 --> BZ031[Go codegen]
  BZ031 --> SVC[Service targets]
```

This is the same **dependency graph** habit Bazel will enforce in code — planning just practices it early.

---

## Part B: Bzlmod and the workspace loading layer

Older Bazel projects used a giant **`WORKSPACE`** file. This fork is **Bzlmod-first**: the module is declared in **`MODULE.bazel`**, and versions resolve into **`MODULE.bazel.lock`**.

### Why it matters

- **Reproducible** dependency resolution: everyone gets the **same** rule versions when the lockfile is committed.  
- **Cleaner** upgrades: bump a module version, run Bazel, commit lock diff — reviewable like any lockfile.  
- **Extensions**: some tools (pip, OCI pulls) need **configuration**, not just a version number — Bzlmod extensions handle that.

### `module()` — naming the workspace

At the top level you give the project a **module name** and version (semantic for your org; demos often use `0.0.0`):

```python
module(
    name = "otel_demo",
    version = "0.0.0",
)
```

This is **not** the Docker image name and **not** the Go module path — it is the **Bazel module** identity.

### `bazel_dep()` — pulling rule sets from the registry

Each line declares a dependency on another **published module** (typically from the **Bazel Central Registry**, BCR):

```python
bazel_dep(name = "rules_go", version = "0.59.0")
bazel_dep(name = "rules_oci", version = "2.3.0")
# ... many more: rules_python, aspect_rules_js, rules_java, etc.
```

**Plain words:** you are saying “this workspace uses these rule packages at these versions.” Starlark rules like `go_binary` come from those modules.

```mermaid
flowchart TB
  MOD[module otel_demo]
  MOD --> R1[rules_go]
  MOD --> R2[rules_oci]
  MOD --> R3[rules_python]
  MOD --> R4[aspect_rules_js]
  MOD --> R5[rules_java / kotlin / ...]
  R1 & R2 & R3 & R4 & R5 --> BL[BUILD.bazel rules]
```

### Module extensions — when a version is not enough

Some modules expose an **extension** object: you call functions on it, then **`use_repo`** to create repositories your code can reference.

**Example A — OCI base images (`rules_oci`)**

You pin **container bases by digest** (good for supply chain). Pattern:

```python
oci = use_extension("@rules_oci//oci:extensions.bzl", "oci")

oci.pull(
    name = "distroless_static_debian12_nonroot",
    digest = "sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1",
    image = "gcr.io/distroless/static-debian12",
    platforms = [
        "linux/amd64",
        "linux/arm64",
    ],
)
```

Then **`use_repo(oci, "distroless_static_debian12_nonroot", ...)`** (plus platform-specific repo names) exposes labels like:

`@distroless_static_debian12_nonroot_linux_amd64//:...`

that `oci_image` rules use as **`base`**.

```mermaid
flowchart LR
  MB[MODULE.bazel]
  MB --> EXT[oci extension]
  EXT --> PULL[oci.pull name + digest]
  PULL --> REPO[@repo // targets]
  REPO --> OIMG[oci_image base = ...]
```

**Example B — Python pip hubs**

Python deps are often declared via **`pip.parse`** (or similar) in the same file: requirements → hub repository → `py_library` / `py_binary` deps. Same **extension** idea: configure once, consume in many `BUILD.bazel` files.

![](https://knowledge-base.local/screenshots/03-module-bazel-extensions.png)

### `MODULE.bazel.lock`

Bazel writes a **lockfile** capturing the resolved graph. **Commit it.** Treat it like:

- **npm:** `package-lock.json`  
- **Go:** `go.sum`  
- **Rust:** `Cargo.lock`

When you bump a `bazel_dep` or change an extension block, the lockfile diff tells reviewers **exactly** what changed in the external graph.

```mermaid
sequenceDiagram
  participant You
  participant MB as MODULE.bazel
  participant B as Bazel resolver
  participant L as MODULE.bazel.lock
  You->>MB: edit deps / extension
  You->>B: bazel build or mod tidy
  B->>L: write/update lock
  You->>You: commit lock diff
```

### Commands when modules act up

```bash
# Show resolved module graph (verbose but useful)
bazelisk mod graph

# Fix common extension / use_repo ordering issues
bazelisk mod tidy
```

If Bazel says **“run bazel mod tidy”**, I run it — arguing rarely wins.

### `.bazelrc` and profiles

**`.bazelrc`** holds default flags. This repo uses **configs** such as:

- **`--config=ci`** — nicer logs for CI  
- **`--config=unit`** — test tag filters (covered more in later chapters)

Optional **local-only** settings go in **`.bazelrc.user`** (gitignored), loaded via:

```text
try-import %workspace%/.bazelrc.user
```

So I can try **remote cache** URLs or experiments without committing secrets.

### Pitfall: duplicate toolchain registration

Copy-pasting tutorials sometimes registers the same **toolchain** twice. The error is ugly; the fix is usually **delete the duplicate** `register_toolchains` or redundant extension stanza and **`mod tidy`**.

### `WORKSPACE` vs Bzlmod — one sentence

**WORKSPACE** = legacy “list everything in one file.” **Bzlmod** = modules + lockfile + extensions — the direction Bazel is pushing for new work.

---

## How Part A and Part B fit together

| Planning piece | Bzlmod piece |
|----------------|--------------|
| M0 “workspace bootstrap” tasks | `MODULE.bazel`, `.bazelversion`, smoke `BUILD.bazel` |
| M1 proto tasks | `bazel_dep` on protobuf rules + `pb/` targets |
| M3 OCI tasks | `rules_oci` + **`oci.pull`** extensions + `oci_image` in services |
| M4 CI tasks | `bazelisk` + `--config=ci` + same graph as local |

```mermaid
flowchart TB
  PLAN[Planning: milestones + BZ IDs]
  MOD[MODULE.bazel + lock]
  BUILD[BUILD.bazel per package]
  PLAN --> MOD --> BUILD
```

---

## What comes next in this series

**Chapter 04** zooms in on **four core Bazel ideas** (graph, hermeticity, analysis vs execution, test tags) — the vocabulary you use every day.

**Chapter 06** onward walks milestones in order: first smoke and lint, then protos, then languages — always on top of the foundation you just read.

---

**Previous:** [`02-what-this-repo-was-before-bazel.md`](./02-what-this-repo-was-before-bazel.md)  
**Next:** [`04-bazel-core-ideas-i-wish-i-knew-on-day-one.md`](./04-bazel-core-ideas-i-wish-i-knew-on-day-one.md)

> **Note:** All **Bzlmod** detail is in **Part B** above. There is no separate “chapter 05” file — it was removed so this chapter stays the single source for module + lock + extensions.
