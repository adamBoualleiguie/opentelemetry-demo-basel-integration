# Ubuntu developer environment for OpenTelemetry demo + Bazel migration

## 1) Purpose of this document

This is document **number 4** in the series. It answers:

- **What do I install on Ubuntu** to work with this repository today?
- **What else do I install** if I touch every language under `src/`?
- **What do I install** to start the Bazel migration described in `2-bazel-architecture-otel-shop-demo.md`?

This document does **not** run installs for you. It lists **realistic requirements** derived from:

- This repo’s `Makefile`, `CONTRIBUTING.md`, `package.json`, `internal/tools/`, protobuf scripts, and services under `src/`.
- The target architecture in `2-bazel-architecture-otel-shop-demo.md` (Bazelisk, Bzlmod, multi-language toolchains, optional remote cache).

Use it as a checklist when provisioning a new Ubuntu workstation or CI runner image.

---

## 2) How to use this checklist

Three tiers:

| Tier | Audience | Goal |
|------|----------|------|
| **A – Demo baseline** | Anyone running the shop via Compose | `make start`, `make build`, repo checks |
| **B – Full polyglot developer** | Contributors editing multiple services | Local builds/tests per language, `ide-gen-proto.sh` |
| **C – Bazel migration** | You, converting the monorepo | Bazel/Bazelisk, strong baseline toolchain, optional cache/RE |

Install **A** first. Add **B** for the languages you touch. Add **C** when you start implementing Bazel (`MODULE.bazel`, `BUILD.bazel`, CI).

---

## 3) Tier A – Ubuntu prerequisites for the current project

These match upstream guidance (`CONTRIBUTING.md`) and root automation.

### 3.1 Core host tools

| Tool | Why you need it (this repo) |
|------|-----------------------------|
| **Git** | Clone, branch, PR workflow, protobuf “clean tree” CI checks. |
| **GNU Make** | Almost everything goes through the root `Makefile` (`build`, `start`, `run-tracetesting`, lint helpers). |
| **Docker Engine** | All services build and run as containers; Compose orchestrates the demo. |
| **Docker Compose v2** | Invoked as `docker compose` (see `Makefile`: `DOCKER_COMPOSE_CMD ?= docker compose`). |

**Ubuntu notes:**

- Prefer the official Docker documentation for Ubuntu (Docker CE + Compose plugin). Ensure your user can run `docker` (group membership or rootless Docker per your org policy).
- Verify: `docker --version`, `docker compose version`.

### 3.2 Runtime helpers often already present

| Tool | Why |
|------|-----|
| **`curl` / `wget`** | Fetch tooling, health checks, ad hoc debugging. |
| **`ca-certificates`** | HTTPS for registries, npm, Go modules, etc. |

### 3.3 Node.js + npm (required for repo checks)

The root `package.json` defines dev dependencies used by `make markdownlint` and `make checklinks`:

- `markdownlint-cli`
- `@umbrelladocs/linkspector`

**What to install:** a current **LTS Node.js** and **npm** (version pin is not in root `package.json`; use an LTS that matches your org standard, typically **20.x or 22.x**).

After clone: `npm install` at repo root (driven by Makefile targets).

### 3.4 Python 3 (required for CI-parity checks locally)

Used by:

- `.github/workflows/checks.yml` → `python3 ./internal/tools/sanitycheck.py`
- `make install-yamllint` / `yamllint` in checks
- Python services and protobuf generation paths (see Tier B)

**What to install:** **Python 3.10+** (3.x from Ubuntu repos often works; CI uses `'3.x'`). **`pip`** for `yamllint` install via Makefile.

### 3.5 Go (small but real requirement)

The root `Makefile` builds Go tools from `internal/tools/go.mod`:

- `misspell`
- `addlicense`

**What to install:** **Go toolchain** matching or newer than `internal/tools/go.mod` (`go 1.12` is a floor; use a modern Go, e.g. **1.22+**, for a sane dev experience).

Command shape (for your own shell): `cd internal/tools && go build -o bin/misspell ...` is what Make automates.

### 3.6 What Tier A does *not* require

To run the **demo in Docker only**, you do not strictly need local JDK, .NET, or Rust on the host—**if** you never run `ide-gen-proto.sh` or native builds outside containers. In practice, Bazel migration and multi-service edits make Tier B almost unavoidable.

---

## 4) Tier B – Full developer stack aligned with `src/`

Install these when you work **outside** Docker for a given language or when running `ide-gen-proto.sh` (non-Docker protobuf generation).

The script explicitly says several tools **may be required**: *protoc, python grpcio-tools, cargo, rebar3* (`ide-gen-proto.sh` header).

### 4.1 Protocol Buffers compiler (`protoc`)

| Need | Services / paths |
|------|------------------|
| **protoc** | Go (`checkout`, `product-catalog`), TypeScript (`frontend`, `react-native-app` via `ts_proto` plugin), and any local regen matching `ide-gen-proto.sh`. |

Also install **language plugins** that match generated code in the repo:

| Plugin / runtime | Why |
|------------------|-----|
| **protoc-gen-go**, **protoc-gen-go-grpc** | Go gRPC output (`--go_out`, `--go-grpc_out` in `ide-gen-proto.sh`). |
| **Node deps for `protoc-gen-ts_proto`** | Frontend/proto TS generation uses `./node_modules/.bin/protoc-gen-ts_proto` — run **`npm install` in `src/frontend`** (and similarly for RN app if you generate there). |
| **`grpcio-tools` (Python)** | `python3 -m grpc_tools.protoc` for Python services. |

**Ubuntu:** Either distro packages (often older `protoc`) or a **known-good `protoc` release** from GitHub—version skew between `protoc` and plugins is a common source of breakage; align with what Docker genproto images use when in doubt.

### 4.2 Go (services)

| Path | Typical host needs |
|------|-------------------|
| `src/checkout`, `src/product-catalog` | **Go** + module downloads, `go fmt`, `go test` where tests exist. |

### 4.3 Node.js / npm (services)

| Path | Typical host needs |
|------|-------------------|
| `src/frontend`, `src/payment` | **Node + npm**; `npm ci` or `npm install` per service README. |
| `src/react-native-app` | Node + **Expo/React Native** toolchain; Android dev often needs **JDK**, **Android SDK**, **CMake** (see React Native upstream docs). |

### 4.4 Python (services)

| Path | Notes |
|------|--------|
| `src/recommendation`, `src/product-reviews`, `src/llm`, `src/load-generator` | **Python 3 + pip**; usually a **venv per service** is best practice. |

For protobuf generation: **`grpcio-tools`** inside the environment you use for `grpc_tools.protoc`.

### 4.5 JVM: Java + Gradle (`src/ad`)

| Tool | Why |
|------|-----|
| **JDK** (version per `src/ad` Gradle config) | `./gradlew installDist`, local runs. |
| **Gradle** | Wrapper `gradlew` is in repo; JDK still required. |

### 4.6 JVM: Kotlin + Gradle (`src/fraud-detection`)

Same pattern: **JDK** + `./gradlew` (Kotlin DSL `build.gradle.kts`).

### 4.7 .NET (`src/accounting`, `src/cart`)

| Tool | Why |
|------|-----|
| **.NET SDK** | `dotnet restore`, `dotnet build`, `dotnet test` (cart has test project). |

Install a SDK version compatible with target frameworks in each `.csproj` (check files under those directories when provisioning).

### 4.8 Rust (`src/shipping`)

| Tool | Why |
|------|-----|
| **Rust (rustc + cargo)** | `cargo build`, `cargo test`; `ide-gen-proto.sh` runs `cargo build` for Rust proto path. |
| **build-essential** | Common C toolchain for native deps on Ubuntu. |

### 4.9 C++ (`src/currency`)

Local iteration often mirrors Dockerfile: **cmake**, **ninja** (optional), **build-essential**, **pkg-config**, sometimes OpenSSL/gRPC C++ deps depending on how you build outside Docker. For minimal friction, many teams use **Docker-only** builds until Bazel supplies a hermetic toolchain.

### 4.10 Ruby (`src/email`)

| Tool | Why |
|------|-----|
| **Ruby** | `src/email/.ruby-version` pins **3.4.8** in this checkout—use **rbenv**, **asdf**, or distro packages if compatible. |
| **Bundler** | `bundle install` pattern used in Ruby services. |

### 4.11 PHP / Composer (`src/quote`)

| Tool | Why |
|------|-----|
| **PHP** + **Composer** | Typical PHP service workflow; Dockerfile reflects extensions your app needs. |

### 4.12 Elixir / Erlang + Mix (`src/flagd-ui`)

| Tool | Why |
|------|-----|
| **Elixir + Erlang/OTP** | `mix`, Phoenix. |
| **rebar3** | `ide-gen-proto.sh` calls `rebar3 grpc_regen` for Elixir gRPC regen pathway. |

Elixir/Erlang versions should match what `mix.ex`s` and Dockerfile expect (check those files when pinning).

### 4.13 Native Android (optional, `src/react-native-app`)

If your goal includes local APK builds (there is also `make build-react-native-android` using Docker):

- **OpenJDK** (Android Gradle Plugin requirement)
- **Android SDK / command-line tools**
- **Accept SDK licenses**
- Often **Node**, **Watchman** (macOS-heavy; optional on Linux)

This is the heaviest Tier B lane; scope it only if you touch the mobile app.

### 4.14 Docker-only protobuf alternative (`docker-gen-proto.sh`)

If you want to avoid installing **protoc** and some plugins locally:

- Requires **Docker** only.
- Uses per-service `genproto/Dockerfile` patterns and root `.env` (CI workflows expect `.env` present).

This aligns with how CI validates generated protobuf consistency (`make clean docker-generate-protobuf` then clean git tree).

---

## 5) Tier C – Tools for the Bazel migration (architecture doc 2)

These are **not** all required to star the demo today; they are what you realistically need when implementing the architecture in `2-bazel-architecture-otel-shop-demo.md`.

### 5.1 Bazelisk (mandatory in modern workflows)

**Bazelisk** is the standard launcher that:

- Reads **`.bazelversion`** (once you add it in the migration).
- Downloads the correct **Bazel** release for the repo.

Install Bazelisk as `bazel` on your PATH (recommended) or invoke `bazelisk` explicitly.

**Ubuntu options:** GitHub `bazelbuild/bazelisk` releases (binary), or your org’s package mirror.

### 5.2 `build-essential` and base C/C++ toolchain

Even if Bazel downloads hermetic toolchains for some languages, Ubuntu almost always needs:

- **`build-essential`** (gcc, g++, make)
- Often **`python3`**, **`git`**, **`zip`**, **`unzip`**, **`tar`** — Bazel and rule sets frequently assume basic utilities.

Rust, C++, and some native Node modules benefit directly.

### 5.3 Optional: `pkg-config`, `zlib`, SSL dev headers

Polyglot native builds on Linux often need:

- **`pkg-config`**
- **`libssl-dev`** (OpenSSL headers)
- **`zlib1g-dev`**

Exact list depends on which Bazel rules and native deps you enable first (`currency`, gRPC native, etc.).

### 5.4 Java JDK (for Bazel JVM rules)

When you onboard `src/ad` / `src/fraud-detection` to Bazel JVM/Kotlin rules, you will use a **JDK** known to your `MODULE.bazel`/toolchain configuration. Installing **JDK 17 or 21** (LTS) on Ubuntu is a typical starting point; **pin** to what the build scripts target.

### 5.5 Go, Node, Python, .NET, Rust (overlap with Tier B)

Bazel does not remove language SDKs from your life immediately:

- Rules still need **compilers/runtimes** or **Bazel-managed toolchains** (depending on setup).
- Practically: keep Tier B SDKs until every language lane uses fully hermetic remote/toolchain configs.

**M2 onward (this fork):**

- **Go:** Install **Go 1.25+** on the host for scripts and parity with CI; Bazel uses **`go_sdk.download`** as described in **`docs/bazel/go-toolchain.md`**.
- **Node:** **`src/payment`** uses **aspect_rules_js** with a **`pnpm-lock.yaml`** checked in. To refresh that lock from **`package-lock.json`**, use **`pnpm import`** (see **`docs/bazel/milestones/m2-completion.md`**). **pnpm** on the dev machine is optional if you only consume the committed lock.

### 5.6 Remote build cache client requirements

Architecture doc 2 assumes future **remote cache**.

**Typical needs:**

- Network access to cache endpoint
- Authentication method your org uses (often `.netrc`, headers, or mTLS)
- **TLS** trust store (`ca-certificates`)

No extra binary beyond `bazel`/`bazelisk` if using HTTP/HTTPS cache; enterprise setups may need a proxy-capable environment.

### 5.7 Optional: BuildBarn / remote execution workers

Only if you adopt **remote execution**:

- Org-specific worker pool
- Often **more RAM**, **more CPU**, **docker**, or **gVisor**-class isolation depending on policy

Treat this as **advanced**, not day-one.

### 5.8 Container image build tooling (when moving OCI to Bazel)

Today images are built with **Docker Buildx** in GitHub Actions.

When Bazel owns OCI assembly:

- You still need **Docker** (or **podman**) depending on rule/tooling choice, **or**
- A **registry** + **push** credentials in CI.

Align with whatever Bazel OCI rule stack you select (implementation detail comes after `MODULE.bazel` exists).

### 5.9 Debugging / introspection (highly useful)

| Tool | Why |
|------|-----|
| **`jq`** | Parse BEP JSON, CI metadata. |
| **`graphviz`** (optional) | Visualize dependency graphs when debugging. |
| **`buildozer`** (Bazel) | Bulk-edit `BUILD` files. |
| **`unused_deps` / buildifier** (optional) | Lint BUILD files and deps (common in mature Bazel repos). |

These are “quality of life” tools for migration at scale.

---

## 6) CI parity on Ubuntu (what GitHub runs vs your laptop)

Your local Ubuntu can mirror `.github/workflows/checks.yml` roughly with:

- **Node** + `npm install` + `make markdownlint`, `make checklinks`
- **Python** + `make install-yamllint` + `yamllint . -f github`
- **Go** + `make misspell`, `make checklicense`
- **Python** + `python3 ./internal/tools/sanitycheck.py`
- **Docker** + reusable image workflow logic is heavier; locally use `make build` / targeted builds

Integration tests workflow runs:

- `make build && docker system prune -f && make run-tracetesting`

So **Tier A** must be solid before you trust local CI-like runs.

---

## 7) Suggested installation order (minimize pain)

1. **Git, Make, Docker + Compose plugin**
2. **Node (LTS) + npm** → root `npm install`
3. **Python 3 + pip** → yamllint, sanity script, Python services
4. **Go** → internal tools builds
5. Add **JDK + Gradle wrappers** when touching `ad` / `fraud-detection`
6. Add **.NET SDK** when touching `accounting` / `cart`
7. Add **Rust** when touching `shipping`
8. Add **protoc + plugins** OR rely on **`docker-gen-proto.sh`**
9. Add **Ruby + Bundler**, **PHP + Composer**, **Elixir/Erlang + rebar3** when touching those services
10. Add **Bazelisk** when you begin authoring Bazel files per architecture doc 2

---

## 8) Security and hygiene (enterprise-friendly)

- Prefer **org-approved** package sources (internal apt mirrors, vetted Node/Ruby installers).
- Use **venvs** for Python, **nvm/fnm** or distro Node—avoid `sudo pip install` globally.
- Pin versions where the repo already hints: **Ruby `3.4.8`**, **Go modules**, **lockfiles** in frontend.
- For Bazel: commit **`.bazelversion`**, use **lockfile** patterns for Bzlmod when you enable them, and avoid non-reproducible `local_path_override` in shared branches.

---

## 9) Traceability to `2-bazel-architecture-otel-shop-demo.md`

| Architecture topic | This doc (Ubuntu install angle) |
|--------------------|----------------------------------|
| Bazelisk + `.bazelversion` | §5.1 |
| Bzlmod / toolchains | §5.4, §5.5 |
| Polyglot `src/*` | §4.x tiers |
| Proto graph / `pb/` | §4.1, §4.14 |
| OCI images | §5.8 |
| Remote cache / RE | §5.6, §5.7 |
| CI fast/full parity | §6 |

---

## 10) Summary table – “what to install”

| Component | Tier A (demo) | Tier B (polyglot dev) | Tier C (Bazel work) |
|-----------|---------------|------------------------|------------------------|
| Git, Make | Yes | Yes | Yes |
| Docker + Compose v2 | Yes | Yes | Yes (often yes for images) |
| Node + npm | Yes (root checks) | Yes (frontend/payment/RN) | Yes |
| Python 3 + pip | Yes | Yes | Yes |
| Go | Yes (internal tools) | Yes | Yes |
| protoc + plugins | No* | Yes (or Docker gen) | Yes (until hermetic gen) |
| JDK / Gradle | No | If JVM services | Recommended for JVM Bazel rules |
| .NET SDK | No | If .NET services | Recommended for .NET targets |
| Rust | No | If `shipping` | Recommended |
| Ruby / Bundler | No | If `email` | If migrating that lane early |
| PHP / Composer | No | If `quote` | If migrating that lane early |
| Elixir / rebar3 | No | If `flagd-ui` + proto | If migrating that lane early |
| C++ toolchain | No | If `currency` native | Yes (`build-essential` min) |
| Android SDK | No | Optional (RN) | Optional |
| Bazelisk | No | Optional early | **Yes** |
| build-essential, pkg-config, libssl-dev | Optional | Recommended | **Recommended** |

\* Tier A can rely on **`docker-gen-proto.sh`** instead of local `protoc` if you never run `ide-gen-proto.sh`.

---

When you outgrow this checklist, the next step is to codify it in **`docs/` or `tools/dev/`** as shell snippets—still without changing application code—so new contributors get one command to validate their laptop against Tier A/B/C.
