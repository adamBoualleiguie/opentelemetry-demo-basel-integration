# Bazel migration charter (M0)

## Purpose

Move this fork toward **Bazel as the primary build and test engine** while keeping Docker Compose runtime and existing contributor workflows working during transition.

## Scope

- In scope: build graph, tests, protobuf codegen, OCI images, CI (GitHub Actions), supply-chain hardening (later milestones).
- Out of scope for this fork unless explicitly added: changing demo business behavior, replacing Helm/K8s upstream docs.

## Branch strategy

- **`main`**: stable line; Bazel changes land via PR.
- **`feat/bazel-*`**: optional feature branches for larger milestones (e.g. `feat/bazel-m1-proto`).
- Short-lived PR branches are encouraged; avoid long-lived divergence from `main`.

## Definition of done (per service)

For each `src/<service>` (tracked in `service-tracker.md`):

1. **Build** via Bazel (library/binary or equivalent).
2. **Test** via Bazel where tests exist (tagged `unit`, etc.).
3. **Image** producible via Bazel (or documented waiver).
4. **Runtime parity** with pre-Bazel behavior (Compose/K8s unchanged unless intentional).

## Roles (update with real names)

| Role        | Owner / contact |
|------------|------------------|
| Sponsor    | _TBD_            |
| Tech lead  | _TBD_            |
| CI contact | _TBD_            |

## Communication

- Use PR descriptions referencing backlog IDs (`BZ-xxx` from `5-bazel-migration-task-backlog.md`).
- Record milestone completion under `docs/bazel/milestones/` (e.g. `m0-completion.md`, `m1-completion.md`).
