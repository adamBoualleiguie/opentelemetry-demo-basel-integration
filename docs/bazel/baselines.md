# Performance and CI baselines (M0)

Record **before** and **after** major milestones to justify Bazel investment.

## How to measure

- **Local `make build`**: run from repo root; note cold (no images) vs warm cache.
- **Local trace tests**: `make run-tracetesting` duration when the stack is already built.
- **GitHub Actions**: use a representative `Checks` workflow run on `main`; note run ID and date.

## M0 placeholder values (fill in on your machine / fork)

| Metric | Cold | Warm | Notes |
|--------|------|------|-------|
| `make build` | _TBD_ | _TBD_ | Docker engine, CPU, disk |
| `make run-tracetesting` | _TBD_ | _TBD_ | |
| `bazelisk build //:smoke` | _TBD_ | _TBD_ | After first fetch of Bazel + deps |
| `bazelisk run //:lint` | _TBD_ | _TBD_ | Needs npm/go/python/yamllint |

## CI (GitHub)

| Workflow | Run / URL | Duration | Date |
|----------|-----------|----------|------|
| Checks (full) | _TBD_ | _TBD_ | _TBD_ |

Update this file at **M1** (proto) and **M4** (Bazel-first CI) at minimum.
