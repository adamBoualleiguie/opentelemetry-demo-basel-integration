# Knowledge base — my Bazel migration journey

This folder is **my** narrated walkthrough of converting the OpenTelemetry Demo (a polyglot monorepo) to **Bazel**, milestone by milestone. For the **full documentation map** (planification series, milestones, upstream readme), start at the root **[README.md](../../README.md)**. I wrote it for three audiences at once:

1. **Future me** — so I do not forget the *why* behind painful choices.  
2. **Someone learning Bazel** — who learns best by following a real repo, not only tutorials.  
3. **Someone who already knows Bazel** — who wants to see how I wired **many languages**, **OCI images**, and **CI** in one place.

## How the journey is ordered

Read the numbered files **in order** (`01` → `40`). **Chapter 05 was removed** (Bzlmod lives only in **chapter 03 · Part B**); after **04** go straight to **06**.

| Block | Files | What you get |
|-------|--------|----------------|
| **Framing** | `01`–`04` | Shop + classic build; planning + **Bzlmod**; core Bazel ideas. |
| **M0–M2** | `06`–`12` | Smoke, lint, governance deep dive, protobufs, Go/Gazelle, first services (**starts at 06**). |
| **M3 languages** | `13`–`24` | Deep dives per stack: Python, Node, Next, JVM, .NET, Rust, C++, Ruby, Elixir, PHP, Envoy/nginx, React Native. |
| **Quality & OCI** | `25`–`28` | Test tags, `sh_test` reality, **M3** breadth recap, dual Docker/Bazel image story, `oci_push`. |
| **M4–M5 & ops** | `29`–`33` | **`bazel_ci`** + **`ci_full`**, allowlist + SBOM release, remote cache, Make/quickstart, deferred E2E/trace. |
| **Meta** | `34`–`36` | Debugging war stories, interview-style “what I can defend”, cheat sheet. |
| **Deep dives** | `37`–`40` | Runfiles, lockfile discipline, error-reading algorithm, git history as syllabus. |

## Tone disclaimer

I use **I / me** on purpose. The upstream OpenTelemetry Demo is a community project; **this narrative is my learning fork** and how I approached the migration. If something reads like advice, treat it as “what worked for me here”, not universal law.

Chapters **25–40** are written to stand alone for **publishing** (diagrams and inlined excerpts). If you also maintain the **git repo**, **`MODULE.bazel`**, **`BUILD.bazel`**, and **`.github/workflows/checks.yml`** remain the authoritative wiring — the prose explains the intent.

---

**Start here:** [`01-the-opentelemetry-astronomy-shop-demo.md`](./01-the-opentelemetry-astronomy-shop-demo.md)
