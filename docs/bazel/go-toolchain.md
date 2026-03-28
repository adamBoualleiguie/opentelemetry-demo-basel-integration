# Go toolchain in Bazel (BZ-042)

This repo uses **Bzlmod** (`MODULE.bazel`) with **rules_go** and **Gazelle**. This note explains choices that affect **reproducibility** vs **host `go`**, and how they tie to **CI**.

---

## Downloaded SDK (`go_sdk.download`)

We register a **downloaded** Go toolchain:

```starlark
go_sdk.download(version = "1.25.0")
```

**Why not only `go_sdk.host()`?**  
Gazelle’s `go_repository` rules run `go` during repository fetch. With only a host SDK, fetch could still see an **older** effective toolchain (or `GOTOOLCHAIN=local` with a version that cannot parse modules requiring **Go ≥ 1.25**), which broke resolution for dependencies such as `golang.org/x/sys` pulled transitively. A **declared download** aligns the fetch toolchain with `go.work` / service `go.mod`.

**CI:** Workflows run **`actions/setup-go`** with **Go 1.25.x** before Bazel where relevant (see `.github/workflows/checks.yml` and `component-build-images.yml`). That satisfies scripts and local `go` expectations; Bazel’s Go actions still use the **pinned SDK** from `go_sdk.download`.

---

## rules_go version vs Go 1.25

Older **rules_go** releases forced `GOEXPERIMENT` values that **Go 1.25** no longer accepts (`nocoverageredesign` / coverage redesign finalization). Symptom: **`go: unknown GOEXPERIMENT coverageredesign`** while building **GoStdlib** for tools like Gazelle.

**Fix:** Use **rules_go ≥ 0.56** (this repo pins **0.59.0** with **gazelle 0.48.0**). See upstream discussion around Go 1.25 and rules_go coverage behavior.

---

## Environment: `GOEXPERIMENT`

`.bazelrc` sets:

```text
common --action_env=GOEXPERIMENT=
common --repo_env=GOEXPERIMENT=
```

This reduces leakage of host experiment flags into stdlib or repository rules. It is defensive; the main Go 1.25 breakage was addressed by **upgrading rules_go**.

---

## `go.work` and `go_deps.from_file`

The root **`go.work`** lists `./src/checkout` and `./src/product-catalog`. **`go_deps.from_file(go_work = "//:go.work")`** tells Gazelle’s extension to resolve third-party modules from that workspace.

Service **`go.mod` files must stay parseable by Gazelle** (no unsupported directives such as `tool` blocks in versions of Gazelle you rely on). Use local `go install` for protoc plugins instead of `tool` stanzas if needed.

---

## Regenerating Go BUILD files

From the repo root:

```bash
bazel run //:gazelle -- update src/checkout src/product-catalog
```

Each service package carries **Gazelle directives** (`prefix`, `exclude genproto`, `resolve` for generated protos → `//pb:...`).

---

## Related docs

- Milestone write-up: `docs/bazel/milestones/m2-completion.md`
- Proto policy: `docs/bazel/proto-policy.md`
