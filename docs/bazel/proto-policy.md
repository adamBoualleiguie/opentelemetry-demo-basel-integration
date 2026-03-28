# Protobuf source of truth and generated code (BZ-037)

## Policy (M1 — transitional)

| Layer | Role |
|--------|------|
| **`pb/demo.proto`** | Canonical API definition. All codegen must derive from this file. |
| **Docker + `make clean docker-generate-protobuf`** | Still the **authoritative** path for **committed** outputs under `src/*` (Go `genproto/`, Python `demo_pb2*.py`, C++, TS, etc.). CI **`protobufcheck`** enforces a clean git tree after this step. |
| **Bazel `//pb:...` targets** | **Parallel proof** that the same `.proto` compiles under the Bazel graph (today: **descriptor set** + **Go** `go_proto_library` for **checkout** and **product-catalog** import paths). |

## Why transitional?

- Dockerfiles and local workflows still **copy pre-generated** files into images.
- A full switch to “generated only in `bazel-out`” requires **M2+** service `BUILD.bazel` files that depend on Bazel-produced protos and image rules that package those outputs.

## Drift between Bazel and committed files

M1 **does not** add an automatic byte-for-byte diff between Bazel-generated Go and `src/*/genproto/oteldemo/*.go` (different `protoc` / plugin patch levels can produce harmless diffs).

**Future (M2):** optional `sh_test` or fixed toolchain pins to assert parity, or stop committing Go gen and use Bazel-only outputs.

## Where to extend next

- **Python / Java / C++ / TS** codegen under Bazel: see `pb/extra/README.md` and extend `MODULE.bazel` with the relevant language rules when you are ready to pay the analysis/build cost in CI.
- **.NET (accounting, BZ-080):** **`//pb:demo.proto`** is copied at build time to **`src/protos/demo.proto`** for **`dotnet publish`** (see **`//tools/bazel:dotnet_publish.bzl`**); C# generation stays in **MSBuild** via **`Grpc.Tools`**, aligned with **`docs/bazel/milestones/m3-completion.md`** §6.
- **Rust (shipping, BZ-090):** **`src/shipping`** builds under **`rules_rust`** + **`crate_universe`** without **`demo.proto`** stubs (**tonic** is for OTLP / **`Status`** only). When the service should consume **`pb/demo.proto`** in Bazel, add **prost** / **`rust_proto_library`** (or equivalent) on **`//pb:demo_proto`** and depend from **`//src/shipping:shipping_lib`**; see **`docs/bazel/milestones/m3-completion.md`** §7.
- **.NET (cart, BZ-081 / BZ-121):** **`//pb:demo.proto`** is copied to **`pb/demo.proto`** in the **`dotnet_publish`** temp tree (**`proto_dest`**) so **`cart.csproj`** **`Protobuf` Include** matches the Docker layout; see **`docs/bazel/milestones/m3-completion.md`** §6.2.
