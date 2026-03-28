# Shipping Service

The Shipping service queries `quote` for price quote, provides tracking IDs,
and the impression of order fulfillment & shipping processes.

## Local

This repo assumes you have rust 1.82 installed. You may use docker, or
[install rust](https://www.rust-lang.org/tools/install).

## Build

From `../../`, run:

```sh
docker compose build shipping
```

## Test

```sh
cargo test
```

## Bazel (BZ-090)

From the repo root (no host **Rust** required for compile — **`rules_rust`** uses a pinned toolchain):

```sh
bazel build //src/shipping:shipping --config=ci
bazel test //src/shipping/... --config=ci
```

Dependencies come from **`Cargo.toml`** / **`Cargo.lock`** via **`crate_universe`** repo **`shipping_crates`**. After changing Rust dependencies, refresh the Bazel lockfile and commit it:

```sh
CARGO_BAZEL_REPIN=1 bazel sync --only=shipping_crates
# commit src/shipping/cargo-bazel-lock.json
```

Targets: **`shipping_lib`** (**`crate_name = "shipping"`**), **`shipping`** binary, **`shipping_test`** (**`unit`** tag). See **`docs/bazel/milestones/m3-completion.md`** §7.

**OCI (BZ-121)** — **`distroless/cc-debian13`** base (same family as **`docker compose` / Dockerfile**), binary at **`/app/shipping`**:

```sh
bazel build //src/shipping:shipping_image //src/shipping:shipping_load --config=ci
# bazel run //src/shipping:shipping_load
# docker run --rm -e SHIPPING_PORT=50050 -p 50050:50050 otel/demo-shipping:bazel
```

Details: **`docs/bazel/milestones/m3-completion.md`** §9.8 and **`docs/bazel/oci-policy.md`** (Rust **`shipping`**).
