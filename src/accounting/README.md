# Accounting Service

This service consumes new orders from a Kafka topic.

## Local Build

To build the service binary, navigate to the root directory of the project and run:

```sh
make generate-protobuf
```

Navigate back to `src/accounting` and execute:

```sh
dotnet build
```

## Bazel (BZ-080)

From the repo root, with **.NET 10 SDK** on `PATH` (NuGet access for restore):

```sh
bazel build //src/accounting:accounting_publish --config=ci
```

**`Accounting.csproj` targets `net10.0`**, so **.NET SDK 8.x is not enough** — you will see **`NETSDK1045`**. Install the **.NET 10** SDK (e.g. from [dotnet download](https://aka.ms/dotnet-download)) or use the same major SDK as **`src/accounting/Dockerfile`** (`mcr.microsoft.com/dotnet/sdk:10.0`).

This copies **`pb/demo.proto`** into the layout expected by **`Accounting.csproj`** (`src/protos/demo.proto`) and runs **`dotnet publish`**. The rule resolves a **.NET 10** SDK (**`DOTNET_ROOT`**, user **`~/.dotnet`**, or **`/usr/share/dotnet`**) and uses a temp **`HOME`** / **`DOTNET_CLI_HOME`** for NuGet inside the sandbox. **`.bazelrc`** forwards **`PATH`** and **`DOTNET_ROOT`** into actions so CI matches local installs. See **`docs/bazel/milestones/m3-completion.md`** §6.

**OCI (BZ-121):**

```sh
bazel build //src/accounting:accounting_image //src/accounting:accounting_load --config=ci
# bazel run //src/accounting:accounting_load
# docker image ls | grep otel/demo-accounting
```

## Docker Build

From the root directory, run:

```sh
docker compose build accounting
```

## Bump dependencies

To bump all dependencies run in Package manager:

```sh
Update-Package -ProjectName Accounting
```
