# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""`dotnet publish` into a declared directory (BZ-080). Proto from `//pb` is copied to match csproj layout."""

def _dotnet_publish_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.name)
    proto = ctx.file.proto
    csproj = ctx.file.csproj

    manifest_lines = []
    inputs = []
    for f in ctx.files.srcs:
        manifest_lines.append("%s\t%s" % (f.path, f.basename))
        inputs.append(f)
    manifest_lines.append("%s\t%s" % (proto.path, "src/protos/demo.proto"))
    inputs.append(proto)

    manifest = ctx.actions.declare_file(ctx.attr.name + "_manifest.txt")
    ctx.actions.write(
        output = manifest,
        content = "\n".join(manifest_lines) + "\n",
    )
    inputs.append(manifest)

    ctx.actions.run_shell(
        mnemonic = "DotnetPublish",
        outputs = [out],
        inputs = depset(direct = inputs),
        command = """
set -euo pipefail
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 DOTNET_CLI_TELEMETRY_OPTOUT=1
CLIENT_HOME="${{HOME:-}}"
# Pick host SDK 10.x even when HOME is unset in the sandbox (lookup passwd home for ~/.dotnet).
_try_dotnet_dir() {{
  base="$1"
  [ -z "$base" ] && return 1
  [ -x "$base/dotnet" ] || return 1
  ver="$("$base/dotnet" --version 2>/dev/null)" || return 1
  case "$ver" in 10.*) printf '%s' "$base"; return 0;; esac
  return 1
}}
_pick_sdk10() {{
  _try_dotnet_dir "${{DOTNET_ROOT:-}}" && return 0
  [ -n "$CLIENT_HOME" ] && _try_dotnet_dir "$CLIENT_HOME/.dotnet" && return 0
  _pw_home="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)"
  [ -n "$_pw_home" ] && _try_dotnet_dir "$_pw_home/.dotnet" && return 0
  _try_dotnet_dir /usr/share/dotnet && return 0
  return 1
}}
SDK10="$(_pick_sdk10)" || true
if [ -n "$SDK10" ]; then
  export PATH="$SDK10:${{PATH:-}}"
fi
# NuGet needs HOME; use a writable temp dir (sandbox often has no real HOME).
DOTHOME="$(mktemp -d)"
export HOME="$DOTHOME"
export DOTNET_CLI_HOME="$DOTHOME/.dotnet"
mkdir -p "$DOTNET_CLI_HOME"
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT" "$DOTHOME"' EXIT
mkdir -p "$ROOT"
while IFS=$(printf '\\t') read -r src dst || [ -n "$src" ]; do
  [ -z "$src" ] && continue
  d="$ROOT/$(dirname "$dst")"
  mkdir -p "$d"
  cp "$src" "$ROOT/$dst"
done < {manifest}
cd "$ROOT"
dotnet restore "{csproj}"
dotnet publish "{csproj}" -c Release -o "{outdir}" /p:TreatWarningsAsErrors=false /p:UseAppHost=false --verbosity minimal
""".format(
            manifest = manifest.path,
            csproj = csproj.basename,
            outdir = out.path,
        ),
        progress_message = "dotnet publish %s" % ctx.label,
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset([out]))]

dotnet_publish = rule(
    implementation = _dotnet_publish_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True, doc = "All project sources (csproj, cs, props, slnx, …)."),
        "csproj": attr.label(allow_single_file = [".csproj"], mandatory = True),
        "proto": attr.label(allow_single_file = [".proto"], mandatory = True, doc = "Canonical proto (e.g. //pb:demo.proto); copied to src/protos/demo.proto."),
    },
    doc = "Runs host `dotnet publish`. Requires SDK matching TargetFramework (e.g. net10.0). Use tag requires-network for restore.",
)
