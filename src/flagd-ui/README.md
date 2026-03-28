# Flagd-ui

This application provides a user interface for configuring the feature
flags of the flagd service.

This is a [Phoenix](https://www.phoenixframework.org/) project.

## Running the application

The application can be run with the rest of the demo using the documented
[docker compose or make commands](https://opentelemetry.io/docs/demo/#running-the-demo).

## Local development

* Run `mix setup` to install and setup dependencies
* Create a `data` folder: `mkdir data`.
* Copy [../flagd/demo.flagd.json](../flagd/demo.flagd.json) to `./data/demo.flagd.json`
  * `cp ../flagd/demo.flagd.json ./data/demo.flagd.json`
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit `localhost:4000` from your browser.

## Programmatic use through the API

This service exposes a REST API to ease its usage in a programmatic way for
power users.

You can read the current configuration using this HTTP call:

```json
$ curl localhost:8080/feature/api/read | jq

{
  "flags": {
    "adFailure": {
      "defaultVariant": "off",
      "description": "Fail ad service",
      "state": "ENABLED",
      "variants": {
        "off": false,
        "on": true
      }
    },
    "adHighCpu": {
      "defaultVariant": "off",
      "description": "Triggers high cpu load in the ad service",
      "state": "ENABLED",
      "variants": {
        "off": false,
        "on": true
      }
    },
    "adManualGc": {
      "defaultVariant": "off",
      "description": "Triggers full manual garbage collections in the ad service",
      "state": "ENABLED",
      "variants": {
        "off": false,
        "on": true
      }
    },
    ...
  }
}
```

You can also write a new settings file by sending a new configuration inside
the `data` field of a POST request body.

Bear in mind that _all_ the data will be rewritten by this write operation.

```sh
$ curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"data": {"$schema":"https://flagd.dev/schema/v0/flags.json","flags":{"adFailure":{"defaultVariant":"on","description":"Fail ad service","state":"ENABLED","variants":{"off":false,"on":true}}...' \
  http://localhost:8080/feature/api/write
```

In addition to the `/read` and `/write` endpoint, we also offer these endpoint
to stay compatible with the old version of Flagd-ui:

* `/read-file` (`GET`)
* `/write-to-file` (`POST`)

## Bazel (build, test, OCI)

This service is also wired for **Bazel** (**BZ-094**): host **Elixir** / **OTP** (match **`src/flagd-ui/Dockerfile`**: **Elixir 1.19.3**, **OTP 28.0.2**), **`gcc`** / **`build-essential`**, and **`git`** (for the **heroicons** git dependency). Builds use **Hex** and **network** during **`mix deps.get`** — targets carry **`requires-network`**.

| Target | Role |
|--------|------|
| **`//src/flagd-ui:flagd_ui_publish`** | Runs **`mix release`** into a declared directory ( **`//tools/bazel:mix_release.bzl`** **`mix_release`** ). |
| **`//src/flagd-ui:flagd_ui_image`** / **`flagd_ui_load`** | **`rules_oci`** image on **`debian:bullseye-20251117-slim`** → **`otel/demo-flagd-ui:bazel`**. |
| **`//src/flagd-ui:flagd_ui_mix_test`** | **`sh_test`** → **`mix test`** (**`tags = ["unit", "requires-network"]`**, **`size = "enormous"`**). |

```bash
# Requires `mix` on PATH (e.g. erlef/setup-beam locally or in CI).
bazel build //src/flagd-ui:flagd_ui_publish //src/flagd-ui:flagd_ui_image --config=ci
bazel test //src/flagd-ui:flagd_ui_mix_test --config=ci
bazel test //src/flagd-ui:flagd_ui_mix_test --config=unit
# optional: bazel run //src/flagd-ui:flagd_ui_load && docker image ls | grep otel/demo-flagd-ui
```

**Why not `rules_elixir`?** Upstream **BCR** **`rules_elixir`** targets raw Elixir/OTP graphs; this **Phoenix** app uses **Mix**, **esbuild**, **Tailwind**, and a **git** dep — the maintainers mirror the **Dockerfile** pipeline with a small **`mix_release`** rule (same idea as **`dotnet_publish`** for .NET).

**Runtime env** for **`docker run`**: set **`SECRET_KEY_BASE`**, **`OTEL_EXPORTER_OTLP_ENDPOINT`**, **`FLAGD_UI_PORT`**, **`PHX_HOST`**, etc., as in **`config/runtime.exs`** (same as Compose).
