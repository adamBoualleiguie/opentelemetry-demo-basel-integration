# Cart Service

This service stores user shopping carts in Valkey.

## Local Build

Run `dotnet restore` and `dotnet build`.

## Docker Build

From the root directory of this repository, run:

```sh
docker compose build cart
```

## Bazel (BZ-081 / BZ-121)

From the repo root, with **.NET 10** SDK on **`PATH`** / **`DOTNET_ROOT`** (NuGet for restore):

```sh
bazel build //src/cart:cart_publish //src/cart:cart_image --config=ci
# optional: bazel run //src/cart:cart_load
```

The Bazel image uses **`dotnet cart.dll`** on **`mcr.microsoft.com/dotnet/aspnet:10.0`** (framework-dependent publish), which differs from **`src/cart/src/Dockerfile`** (musl single-file **`./cart`**). See **`docs/bazel/milestones/m3-completion.md`** §6.2 and §9.9.

**Tests (M4 / BZ-081):** **`bazel test //src/cart:cart_dotnet_test --config=ci`** runs xUnit via host **`dotnet`** (NuGet **`requires-network`**; **.NET 10** SDK required — same discovery as **`dotnet_publish`**). Equivalent: **`dotnet test src/cart/tests/cart.tests.csproj`** from a tree with **`pb/demo.proto`** at **`src/cart/pb/demo.proto`**.

**Runtime:** set **`VALKEY_ADDR`** (and OTLP variables if needed), same as Docker Compose; default gRPC port **7070** (**.env** **`CART_PORT`**).
