# Starlark / BUILD file style (M0 — BZ-016)

## Buildifier (recommended)

Use [Buildifier](https://github.com/bazelbuild/buildtools) to format `BUILD.bazel`, `MODULE.bazel`, and `*.bzl` files:

```bash
buildifier -r .
```

## Conventions (this fork)

- Prefer **Bzlmod** (`MODULE.bazel`) over legacy `WORKSPACE` dependencies.
- Keep **Apache-2.0** license headers on new build files and shell wrappers, consistent with the repo.
- Name migration-related docs under `docs/bazel/` with milestone prefixes (`m0-`, `m1-`, …).

CI enforcement of Buildifier may be added in a later milestone.
