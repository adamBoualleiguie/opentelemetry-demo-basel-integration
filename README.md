<!-- markdownlint-disable-next-line -->
# <img src="https://opentelemetry.io/img/logos/opentelemetry-logo-nav.png" alt="OTel logo" width="45"> OpenTelemetry Demo — **Bazel migration fork**

[![Integration Tests](https://github.com/open-telemetry/opentelemetry-demo/actions/workflows/run-integration-tests.yml/badge.svg)](https://github.com/open-telemetry/opentelemetry-demo/actions/workflows/run-integration-tests.yml)

This repository is a **practical, step-by-step example** of integrating **[Bazel](https://bazel.build/)** into a **polyglot monorepo**: the **[OpenTelemetry Astronomy Shop](https://opentelemetry.io/docs/demo/)** — many languages (Go, Node, Python, JVM, .NET, Rust, C++, Ruby, Elixir, PHP, …), Docker Compose for runtime, and container images built both **via Dockerfiles** and **via Bazel (`rules_oci`)**.

**What you can learn here**

- How to **plan** a migration (milestones M0–M6, task IDs, backlog).
- How **Bzlmod** (`MODULE.bazel`, lockfile, extensions) anchors a real workspace.
- How **one CI graph** (`ci_full.sh`, tag-filtered tests) gates a heterogeneous repo.
- How **dual build tracks** (Compose + Bazel OCI) coexist without pretending they are identical.

**Quick start (run the shop)** — same as upstream: Docker or Kubernetes — see **[OpenTelemetry demo docs](https://opentelemetry.io/docs/demo/)** or the preserved upstream-style readme: **[`docs/otel-readme.md`](docs/otel-readme.md)** (badges, vendor table, maintainers).

**Quick start (Bazel in this fork)**

```bash
# Full graph parity with GitHub Actions bazel_ci
bash ./tools/bazel/ci/ci_full.sh

# Faster loop (skips most oci_image builds)
bash ./tools/bazel/ci/ci_fast.sh

# Unit tests only
bazelisk test //... --config=ci --config=unit --build_tests_only
```

See **[`CONTRIBUTING.md`](CONTRIBUTING.md)** for toolchain expectations and **[`docs/bazel/quickstart.md`](docs/bazel/quickstart.md)** for a short command table.

---

## Documentation map

Use this as a **learning path**: strategy → architecture → concepts → environment → backlog → narrated knowledge base → technical milestone reports.

### 1) Planification (strategy series)

**Index:** [`docs/planification/README.md`](docs/planification/README.md)

| Doc | What it is |
|-----|------------|
| [**1 — Bazel integration**](docs/planification/1-bazel-integration.md) | **Why** adopt Bazel here: value, risks, phased rollout, CI/security direction — the “should we?” and “in what order?” story. |
| [**2 — Architecture (Astronomy Shop)**](docs/planification/2-bazel-architecture-otel-shop-demo.md) | **Target shape**: repo layout, diagrams, per-service mapping, OCI graph, test taxonomy — the blueprint the migration implements. |
| [**3 — Concepts for OTel architecture**](docs/planification/3-bazel-concepts-for-otel-architecture.md) | **Vocabulary**: workspace, package, target, DAG, hermeticity, platforms — read this before fighting Starlark errors. |
| [**4 — Dev environment (Ubuntu)**](docs/planification/4-bazel-dev-environment-ubuntu.md) | **Machine setup**: tiers of tooling (Docker, languages, Bazelisk) so local and CI match what `BUILD` files assume. |
| [**5 — Migration task backlog**](docs/planification/5-bazel-migration-task-backlog.md) | **Work breakdown**: epics, **BZ-xxx** IDs, acceptance criteria — the checklist that turns “M3” into concrete tasks. |

### 2) Knowledge base (narrated walkthrough, **01 → 40**)

First-person **I**-style chapters: commands, diagrams, interview lines. Read in order after skimming planification.

| Chapters | Theme |
|----------|--------|
| [**01**](docs/knowledge-base/01-the-opentelemetry-astronomy-shop-demo.md) – [**04**](docs/knowledge-base/04-bazel-core-ideas-i-wish-i-knew-on-day-one.md) | What the demo is, **before Bazel**, planning + **Bzlmod** (ch. 03), **core Bazel ideas**. |
| [**06**](docs/knowledge-base/06-milestone-m0-smoke-lint-and-ci-whisper.md) – [**12**](docs/knowledge-base/12-rules-oci-oci-pull-and-digests.md) | **M0–M2**, governance, **M1 protos**, Gazelle, build hygiene, **`oci.pull`** / digests. |
| [**13**](docs/knowledge-base/13-language-python-services-and-pip.md) – [**24**](docs/knowledge-base/24-react-native-android-and-the-expo-edges.md) | **Language lanes**: Python, Node/payment, Next frontend, JVM, .NET, Rust, C++, Ruby, Elixir, PHP, Envoy/nginx, **React Native / Android**. |
| [**25**](docs/knowledge-base/25-test-tags-flakes-network-and-sh-test-strategy.md) – [**31**](docs/knowledge-base/31-remote-cache-bazelrc-user-and-ci-secrets.md) | **Test tags**, **M3** recap, **dual OCI** policy, **`oci_push`**, **M4 CI**, **M5** allowlist/SBOM, **remote cache**. |
| [**32**](docs/knowledge-base/32-make-wrappers-quickstart-and-contributing-notes.md) – [**40**](docs/knowledge-base/40-git-history-as-my-lab-notebook.md) | Make wrappers, deferred Cypress/Tracetest, **debugging**, **interview patterns**, cheat sheet, runfiles, lockfile, reading errors, **git history** as syllabus. |

**Index & reading order:** [`docs/knowledge-base/README.md`](docs/knowledge-base/README.md) · **Chapter 05** is intentionally omitted (Bzlmod is covered in **chapter 03**).

<details>
<summary><strong>One-line blurbs (all knowledge-base chapters)</strong></summary>

| # | File | In one sentence |
|---|------|-----------------|
| 01 | [`01-the-opentelemetry-astronomy-shop-demo.md`](docs/knowledge-base/01-the-opentelemetry-astronomy-shop-demo.md) | What the Astronomy Shop is and how observability fits. |
| 02 | [`02-what-this-repo-was-before-bazel.md`](docs/knowledge-base/02-what-this-repo-was-before-bazel.md) | Make, Compose, Dockerfiles, and classic CI **before** Bazel. |
| 03 | [`03-how-i-used-the-planning-doc-series.md`](docs/knowledge-base/03-how-i-used-the-planning-doc-series.md) | Milestones, BZ IDs, epics, **`MODULE.bazel`** / lock / extensions. |
| 04 | [`04-bazel-core-ideas-i-wish-i-knew-on-day-one.md`](docs/knowledge-base/04-bazel-core-ideas-i-wish-i-knew-on-day-one.md) | Graph, hermeticity, analysis vs execution, tags — day-one vocabulary. |
| 06 | [`06-milestone-m0-smoke-lint-and-ci-whisper.md`](docs/knowledge-base/06-milestone-m0-smoke-lint-and-ci-whisper.md) | **M0**: smoke target, Bazel in CI, lint parity. |
| 07 | [`07-governance-charter-baselines-and-risk.md`](docs/knowledge-base/07-governance-charter-baselines-and-risk.md) | Charter, baselines, risk register. |
| 08 | [`08-milestone-m1-protobufs-as-the-spine.md`](docs/knowledge-base/08-milestone-m1-protobufs-as-the-spine.md) | **M1**: protos as the shared spine. |
| 09 | [`09-gazelle-go-importpaths-and-sanity.md`](docs/knowledge-base/09-gazelle-go-importpaths-and-sanity.md) | Gazelle, Go import paths, sanity checks. |
| 10 | [`10-milestone-m2-first-language-wave.md`](docs/knowledge-base/10-milestone-m2-first-language-wave.md) | **M2**: first full Go wave end-to-end. |
| 11 | [`11-build-style-buildifier-and-bazelignore.md`](docs/knowledge-base/11-build-style-buildifier-and-bazelignore.md) | Buildifier, `.bazelignore`, repo hygiene. |
| 12 | [`12-rules-oci-oci-pull-and-digests.md`](docs/knowledge-base/12-rules-oci-oci-pull-and-digests.md) | `rules_oci`, digest-pinned bases. |
| 13 | [`13-language-python-services-and-pip.md`](docs/knowledge-base/13-language-python-services-and-pip.md) | Python services, `pip` / Bazel. |
| 14 | [`14-language-node-payment-and-npm-with-aspect-rules-js.md`](docs/knowledge-base/14-language-node-payment-and-npm-with-aspect-rules-js.md) | Payment service, **Aspect rules_js**, npm/pnpm. |
| 15 | [`15-language-nextjs-frontend-the-beast.md`](docs/knowledge-base/15-language-nextjs-frontend-the-beast.md) | Next.js frontend, `next_build`, memory. |
| 16 | [`16-language-jvm-ad-and-kotlin-fraud-detection.md`](docs/knowledge-base/16-language-jvm-ad-and-kotlin-fraud-detection.md) | JVM **ad**, Kotlin **fraud-detection**. |
| 17 | [`17-language-dotnet-accounting-and-cart.md`](docs/knowledge-base/17-language-dotnet-accounting-and-cart.md) | .NET **accounting** and **cart**. |
| 18 | [`18-language-rust-shipping.md`](docs/knowledge-base/18-language-rust-shipping.md) | Rust **shipping**. |
| 19 | [`19-language-cpp-currency-and-proto-smoke.md`](docs/knowledge-base/19-language-cpp-currency-and-proto-smoke.md) | C++ **currency**, proto smoke. |
| 20 | [`20-language-ruby-email-and-bundle-vendoring.md`](docs/knowledge-base/20-language-ruby-email-and-bundle-vendoring.md) | Ruby **email**, Bundler vendoring. |
| 21 | [`21-language-elixir-flagd-ui-and-custom-mix-release.md`](docs/knowledge-base/21-language-elixir-flagd-ui-and-custom-mix-release.md) | Elixir **flagd-ui**, Mix release. |
| 22 | [`22-language-php-quote-and-composer.md`](docs/knowledge-base/22-language-php-quote-and-composer.md) | PHP **quote**, Composer. |
| 23 | [`23-envoy-nginx-baked-config-and-oci.md`](docs/knowledge-base/23-envoy-nginx-baked-config-and-oci.md) | Envoy + nginx edge, baked config OCI. |
| 24 | [`24-react-native-android-and-the-expo-edges.md`](docs/knowledge-base/24-react-native-android-and-the-expo-edges.md) | Expo / RN, Android APK, hermetic SDK. |
| 25 | [`25-test-tags-flakes-network-and-sh-test-strategy.md`](docs/knowledge-base/25-test-tags-flakes-network-and-sh-test-strategy.md) | Tags, `requires-network`, **`sh_test`** strategy. |
| 26 | [`26-milestone-m3-when-the-wave-crashed-in-a-good-way.md`](docs/knowledge-base/26-milestone-m3-when-the-wave-crashed-in-a-good-way.md) | **M3** breadth recap. |
| 27 | [`27-oci-policy-dual-build-dockerfile-vs-bazel.md`](docs/knowledge-base/27-oci-policy-dual-build-dockerfile-vs-bazel.md) | Dockerfile matrix vs Bazel OCI. |
| 28 | [`28-oci-push-checkout-and-registry-auth.md`](docs/knowledge-base/28-oci-push-checkout-and-registry-auth.md) | `oci_push` pilot on **checkout**. |
| 29 | [`29-milestone-m4-when-ci-became-the-boss.md`](docs/knowledge-base/29-milestone-m4-when-ci-became-the-boss.md) | **M4**: `bazel_ci`, `ci_full.sh`. |
| 30 | [`30-milestone-m5-allowlist-sbom-release-workflow.md`](docs/knowledge-base/30-milestone-m5-allowlist-sbom-release-workflow.md) | **M5**: allowlist, SBOM, release workflow. |
| 31 | [`31-remote-cache-bazelrc-user-and-ci-secrets.md`](docs/knowledge-base/31-remote-cache-bazelrc-user-and-ci-secrets.md) | Remote cache, `.bazelrc.user`. |
| 32 | [`32-make-wrappers-quickstart-and-contributing-notes.md`](docs/knowledge-base/32-make-wrappers-quickstart-and-contributing-notes.md) | Make targets, quickstart notes. |
| 33 | [`33-cypress-tracetest-and-what-i-deferred-on-purpose.md`](docs/knowledge-base/33-cypress-tracetest-and-what-i-deferred-on-purpose.md) | Deferred Cypress / Tracetest. |
| 34 | [`34-debugging-playbook-what-usually-broke.md`](docs/knowledge-base/34-debugging-playbook-what-usually-broke.md) | Debugging playbook. |
| 35 | [`35-interview-mode-patterns-i-can-defend.md`](docs/knowledge-base/35-interview-mode-patterns-i-can-defend.md) | Interview-defensible patterns. |
| 36 | [`36-appendix-cheat-sheet-and-reading-order.md`](docs/knowledge-base/36-appendix-cheat-sheet-and-reading-order.md) | Cheat sheet & order. |
| 37 | [`37-starlark-runfiles-and-why-scripts-break-in-test.md`](docs/knowledge-base/37-starlark-runfiles-and-why-scripts-break-in-test.md) | Runfiles and `sh_test`. |
| 38 | [`38-module-bazel-lock-and-reproducible-fetches.md`](docs/knowledge-base/38-module-bazel-lock-and-reproducible-fetches.md) | `MODULE.bazel.lock` discipline. |
| 39 | [`39-how-i-read-a-bazel-error-without-rage-quitting.md`](docs/knowledge-base/39-how-i-read-a-bazel-error-without-rage-quitting.md) | Reading Bazel errors systematically. |
| 40 | [`40-git-history-as-my-lab-notebook.md`](docs/knowledge-base/40-git-history-as-my-lab-notebook.md) | Git history as migration syllabus. |

</details>

### 3) Technical Bazel docs & milestones

| Area | Entry |
|------|--------|
| **Index** | [`docs/bazel/README.md`](docs/bazel/README.md) |
| **M0–M5 reports** | [`docs/bazel/milestones/`](docs/bazel/milestones/) (`m0-completion.md` … `m5-completion.md`) |
| **Test tags** | [`docs/bazel/test-tags.md`](docs/bazel/test-tags.md) |
| **OCI policy / push / allowlist** | [`docs/bazel/oci-policy.md`](docs/bazel/oci-policy.md), [`docs/bazel/oci-registry-push.md`](docs/bazel/oci-registry-push.md), [`docs/bazel/oci-base-allowlist.md`](docs/bazel/oci-base-allowlist.md) |
| **Charter & risk** | [`docs/bazel/charter.md`](docs/bazel/charter.md), [`docs/bazel/risk-register.md`](docs/bazel/risk-register.md), [`docs/bazel/baselines.md`](docs/bazel/baselines.md) |

### 4) Upstream demo readme (vendors, badges, maintainers)

- **[`docs/otel-readme.md`](docs/otel-readme.md)** — original-style OpenTelemetry Demo README moved here so the root stays migration-focused.

---

## Contributing

See **[`CONTRIBUTING.md`](CONTRIBUTING.md)**. Align Bazel changes with **[`docs/planification/5-bazel-migration-task-backlog.md`](docs/planification/5-bazel-migration-task-backlog.md)** and milestone docs under **`docs/bazel/milestones/`**.

## License

Apache 2.0 — see **[`LICENSE`](LICENSE)**.
