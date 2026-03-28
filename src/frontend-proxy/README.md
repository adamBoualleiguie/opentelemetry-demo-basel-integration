# Frontend Proxy Service

This service acts as a reverse proxy for the various user-facing web interfaces.

## Modifying the Envoy Configuration

The envoy configuration is generated from the `envoy.tmpl.yaml` file in this
directory. Environment variables are substituted at deploy-time.

## Bazel (**BZ-097**)

Build a container image with **`rules_oci`** on a digest-pinned **`envoyproxy/envoy:v1.34-latest`** base. A **`genrule`** runs **`bake_envoy.sh`** (host **`envsubst`**) so **`envoy.tmpl.yaml`** becomes a fixed **`/etc/envoy/envoy.yaml`** in the image. Defaults match **docker-compose** service names (see **`bake_envoy.sh`**).

This differs from **`Dockerfile`**, which installs **`gettext-base`** and runs **`envsubst` when the container starts**. To change upstreams without rebuilding, use Compose; for Bazel, export overrides before **`bazel build`** or edit defaults in **`bake_envoy.sh`**.

**Requires** **`envsubst`** on the build host (e.g. **`apt install gettext-base`**).

```bash
bazel build //src/frontend-proxy:frontend_proxy_image --config=ci
bazel test //src/frontend-proxy:frontend_proxy_config_test --config=ci
bazel run //src/frontend-proxy:frontend_proxy_load   # docker load → otel/demo-frontend-proxy:bazel
```

See **`docs/bazel/milestones/m3-completion.md`** (**§7.7**) and **`docs/bazel/oci-policy.md`** (Envoy row).
