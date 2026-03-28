# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""`mix release` into a declared directory (BZ-094). Host Elixir/OTP + network (Hex + git deps)."""

def _rel_path_under_package(pkg, f):
    """Path relative to the Mix project root inside the temp tree."""
    sp = f.short_path
    prefix = pkg + "/"
    if sp.startswith(prefix):
        return sp[len(prefix):]
    return f.basename

def _mix_release_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.name)
    pkg = ctx.label.package
    app = ctx.attr.release_app

    manifest_lines = []
    inputs = []
    for f in ctx.files.srcs:
        manifest_lines.append("%s\t%s" % (f.path, _rel_path_under_package(pkg, f)))
        inputs.append(f)

    manifest = ctx.actions.declare_file(ctx.attr.name + "_manifest.txt")
    ctx.actions.write(
        output = manifest,
        content = "\n".join(manifest_lines) + "\n",
    )
    inputs.append(manifest)

    ctx.actions.run_shell(
        mnemonic = "MixRelease",
        outputs = [out],
        inputs = depset(direct = inputs),
        command = """
set -euo pipefail
export MIX_ENV=prod
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
# Writable HOME for Hex/Rebar and mix archives (sandbox often has no real HOME).
MIXHOME="$(mktemp -d)"
export HOME="$MIXHOME"
trap 'rm -rf "$MIXHOME" "$ROOT"' EXIT
ROOT="$(mktemp -d)"
mkdir -p "$ROOT"
while IFS=$(printf '\\t') read -r src dst || [ -n "$src" ]; do
  [ -z "$src" ] && continue
  d="$ROOT/$(dirname "$dst")"
  mkdir -p "$d"
  cp "$src" "$ROOT/$dst"
done < {manifest}
cd "$ROOT"
git config --global --add safe.directory '*' 2>/dev/null || true
if ! command -v mix >/dev/null 2>&1; then
  echo "mix not found on PATH; install Elixir/OTP (see src/flagd-ui/README.md Bazel section)." >&2
  exit 1
fi
mix local.hex --force
mix local.rebar --force
mix deps.get --only prod
mix deps.compile
mix assets.setup
mix assets.deploy
mix compile
mix release {release_app}
REL="$ROOT/_build/prod/rel/{release_app}"
if [ ! -d "$REL" ]; then
  echo "mix release did not produce $REL" >&2
  exit 1
fi
mkdir -p "{outdir}"
cp -a "$REL/." "{outdir}/"
""".format(
            manifest = manifest.path,
            release_app = app,
            outdir = out.path,
        ),
        progress_message = "mix release %s" % ctx.label,
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset([out]))]

mix_release = rule(
    implementation = _mix_release_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True, doc = "Mix project tree (mix.exs, config, lib, assets, priv, rel, …)."),
        "release_app": attr.string(default = "flagd_ui", doc = "Release name from mix.exs :releases."),
    },
    doc = "Runs host `mix release`. Requires Elixir/OTP compatible with mix.exs (e.g. ~> 1.19) and network for Hex/git (tag `requires-network`).",
)
