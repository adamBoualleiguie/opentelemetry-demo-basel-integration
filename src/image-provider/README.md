# Image Provider Service

Serves static demo images over HTTP via **nginx** (OpenTelemetry-instrumented **nginxinc/nginx-unprivileged** image in Compose).

## Configuration

**`nginx.conf.template`** is rendered with **`envsubst`** at container start in **`Dockerfile`**. Variables: **`OTEL_COLLECTOR_HOST`**, **`IMAGE_PROVIDER_PORT`**, **`OTEL_COLLECTOR_PORT_GRPC`**, **`OTEL_SERVICE_NAME`**.

## Bazel (**BZ-097**)

**`bake_nginx.sh`** applies the same **`envsubst`** variable list as the **Dockerfile** **`CMD`**, but at **build** time, producing a baked **`/etc/nginx/nginx.conf`** layered with **`static/**`** under **`/static`**.

**Requires** **`envsubst`** on the build host (e.g. **`apt install gettext-base`**).

```bash
bazel build //src/image-provider:image_provider_image --config=ci
bazel test //src/image-provider:image_provider_config_test --config=ci
bazel run //src/image-provider:image_provider_load   # docker load → otel/demo-image-provider:bazel
```

Base image: **`docker.io/nginxinc/nginx-unprivileged:1.29.0-alpine3.22-otel`** (digest-pinned in **`MODULE.bazel`**). The OCI image sets **`user = "101"`** to match the unprivileged nginx image.

See **`docs/bazel/milestones/m3-completion.md`** (**§7.7**) and **`docs/bazel/oci-policy.md`** (nginx row).
