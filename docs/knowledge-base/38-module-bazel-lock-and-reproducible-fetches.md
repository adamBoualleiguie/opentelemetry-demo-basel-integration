# 38 — `MODULE.bazel.lock`: reproducible fetches and the social contract of upgrades

**Previous:** [`37-starlark-runfiles-and-why-scripts-break-in-test.md`](./37-starlark-runfiles-and-why-scripts-break-in-test.md)

Bzlmod resolves a module graph and records the result in **`MODULE.bazel.lock`**. Treat that file like **`go.sum`**: it is how you say “this workspace resolves **here**, not wherever the internet is today.”

---

## When I bump dependencies

1. Edit **`MODULE.bazel`** (version bumps, new **`bazel_dep`**, new **`use_repo`**).  
2. Run a build or **`bazel mod tidy`** as Bazel prompts.  
3. Commit the lockfile diff **with intent** — reviewers should see **what** changed in the resolved graph, not a mystery blob.

---

## Merge conflicts

Lockfile conflicts are normal on active branches. Pragmatic flow:

- Pick one side as a starting point, then  
- Re-run **`bazel mod tidy`** (or a build) to regenerate a **coherent** lock for **your** merged **`MODULE.bazel`**.

Avoid “resolve conflict by hand-editing JSON-ish lock internals” unless you enjoy pain.

---

## Relationship to CI cache keys

The **`bazel_ci`** job keys disk cache on **`.bazelversion`** + **`MODULE.bazel.lock`**. When the lock changes, cache **misses** are **expected** — correctness wins.

---

## Interview talking point

> “Lockfiles turn dependency resolution from a **conversation** into an **artifact** you can **diff** in PR review.”

```mermaid
flowchart LR
  MB[MODULE.bazel intent]
  MB --> RES[Bzlmod resolver]
  RES --> LOCK[MODULE.bazel.lock fact]
  LOCK --> CI[CI + teammates use same graph]
```

---

**Next:** [`39-how-i-read-a-bazel-error-without-rage-quitting.md`](./39-how-i-read-a-bazel-error-without-rage-quitting.md)
