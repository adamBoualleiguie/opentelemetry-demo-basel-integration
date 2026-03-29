# OCI registry push (BZ-123, M4)

This fork uses **`rules_oci`** **`oci_push`** to upload images built by **`oci_image`** to a container registry. **`oci_load`** remains the local **`docker load`** path.

## Prerequisites

- Registry credentials on the machine that runs **`bazel run`**:
  - **`docker login`** / **`podman login`**, or
  - **`crane auth login`** (see [go-containerregistry](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane_auth_login.md)).
- Network egress to the registry.

## Reference target: `checkout`

| Item | Value |
|------|--------|
| **Push rule** | `//src/checkout:checkout_push` |
| **Image** | `//src/checkout:checkout_image` (Go binary on distroless static) |

### Examples

```bash
# Repository and tag via flags (recommended — no secrets in BUILD files):
bazel run //src/checkout:checkout_push -- \
  --repository ghcr.io/myorg/opentelemetry-demo/checkout \
  --tag "$(git rev-parse --short HEAD)"

# Multiple extra tags:
bazel run //src/checkout:checkout_push -- \
  --repository docker.io/otel/demo-checkout \
  --tag dev --tag latest
```

If **`repository`** is fixed in **`BUILD.bazel`**, you can omit **`--repository`**; this repo leaves it unset so CI can inject **`ghcr.io/...`** vs **Docker Hub** per environment.

## GitHub Actions secrets (conceptual)

| Secret / token | Typical use |
|----------------|-------------|
| **`GITHUB_TOKEN`** | GHCR push from **`docker/login-action`** (scoped to the repo). |
| **`DOCKER_USERNAME`** / **`DOCKER_PASSWORD`** | Docker Hub (already referenced in **`component-build-images.yml`**). |

**Read-only PRs:** do not run **`oci_push`** on untrusted forks without guarding secrets. Prefer **`workflow_dispatch`** or **`push` to `main` / release tags** for publish jobs (**BZ-633**, M5).

### Release workflow (this fork)

**`.github/workflows/bazel-release-oci.yml`** runs on **`release: published`** and **`workflow_dispatch`**: builds **`//src/checkout:checkout_image`**, loads **`otel/demo-checkout:bazel`**, attaches an **SBOM** (**BZ-721**), runs an **Anchore** vulnerability scan (**BZ-722**, non-blocking by default), and **pushes** only when the repository secret **`BAZEL_CHECKOUT_PUSH_REPOSITORY`** is set (full image path, e.g. **`ghcr.io/org/demo-checkout-bazel`**). **`docker/login-action`** uses **`GITHUB_TOKEN`** for GHCR.

## Rolling out more services

Copy the **`oci_push`** block from **`src/checkout/BUILD.bazel`**, point **`image`** at the service’s **`oci_image`**, and document the target in **`docs/bazel/oci-policy.md`** (BZ-122 matrix).

## Related

- **`docs/bazel/oci-policy.md`** — digests, layering, BZ-122 dual-build matrix.
- **`docs/bazel/milestones/m4-completion.md`** — M4 success criteria.
