# OCI / container image policy (BZ-120)

This note records the **chosen direction** for building container images with Bazel in this fork, per **`5-bazel-migration-task-backlog.md`** epic **M — OCI images** (BZ-120).

## Decision (M3)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| **Rule set** | **`rules_oci`** (Bazel Central Registry) for `oci_image` / layering | Hermetic, Bzlmod-friendly, aligns with modern Bazel OCI workflows; avoids legacy `container_image` patterns where possible. |
| **Base images** | **Pin by digest** in `MODULE.bazel` via **`oci.pull`** | Reproducibility and supply-chain review (feeds later BZ-720 policy). |
| **Pilot (BZ-121)** | **`checkout`** — **`oci_image`** + **`oci_load`** | Proves layering, digest-pinned base, and `docker load` from Bazel. |

## BZ-121 pilot (implemented)

| Item | Detail |
|------|--------|
| **Image target** | `//src/checkout:checkout_image` |
| **Docker load bundle** | `//src/checkout:checkout_load` — run `bazel run //src/checkout:checkout_load`, then `docker image ls` for tag **`otel/demo-checkout:bazel`**. |
| **Base** | `gcr.io/distroless/static-debian12` @ **`sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1`** (nonroot variant; pulled for **linux/amd64** and **linux/arm64**; image rule uses **amd64** base today). |
| **App layout** | Binary at **`/usr/src/app/checkout`**, **`WORKDIR`** `/usr/src/app`, port **5050/tcp** exposed in image metadata. |

Narrative and troubleshooting (toolchains, `bazel mod tidy`): **`docs/bazel/milestones/m3-completion.md`** §9.

## Out of scope at BZ-120

- Full matrix parity with **`component-build-images.yml`** (BZ-122, **M4**).
- Push targets and secrets (BZ-123, **M4**).

## References

- Milestone narrative: `docs/bazel/milestones/m3-completion.md` (Epic M, BZ-120–121).
- Service tracker: `docs/bazel/service-tracker.md`.
