# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""`composer install` into a declared directory (BZ-095). Host PHP + Composer + network (Packagist)."""

def _rel_path_under_package(pkg, f):
    """Path relative to the project root inside the temp tree."""
    sp = f.short_path
    prefix = pkg + "/"
    if sp.startswith(prefix):
        return sp[len(prefix):]
    return f.basename

def _composer_install_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.name)
    pkg = ctx.label.package

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

    extra = ctx.attr.composer_install_args
    ctx.actions.run_shell(
        mnemonic = "ComposerInstall",
        outputs = [out],
        inputs = depset(direct = inputs),
        command = """
set -euo pipefail
export COMPOSER_NO_INTERACTION=1 COMPOSER_ALLOW_SUPERUSER=1
COMPOSER_HOME="$(mktemp -d)"
export COMPOSER_HOME
trap 'rm -rf "$COMPOSER_HOME" "$ROOT"' EXIT
ROOT="$(mktemp -d)"
mkdir -p "$ROOT"
while IFS=$(printf '\\t') read -r src dst || [ -n "$src" ]; do
  [ -z "$src" ] && continue
  d="$ROOT/$(dirname "$dst")"
  mkdir -p "$d"
  cp "$src" "$ROOT/$dst"
done < {manifest}
cd "$ROOT"
if ! command -v composer >/dev/null 2>&1; then
  echo "composer not found on PATH; install Composer (see src/quote/README.md Bazel section)." >&2
  exit 1
fi
composer install {extra_args}
mkdir -p "{outdir}"
cp -a "$ROOT"/. "{outdir}/"
""".format(
            manifest = manifest.path,
            extra_args = extra,
            outdir = out.path,
        ),
        progress_message = "composer install %s" % ctx.label,
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset([out]))]

composer_install = rule(
    implementation = _composer_install_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True, doc = "PHP app tree (composer.json, app/, public/, src/, …)."),
        "composer_install_args": attr.string(
            default = "--ignore-platform-reqs --no-interaction --no-plugins --no-scripts --no-dev --prefer-dist",
            doc = "Arguments after `composer install` (match Dockerfile vendor stage unless you need dev deps).",
        ),
    },
    doc = "Runs host `composer install`. Requires PHP + Composer on PATH and network for Packagist. Use tag requires-network.",
)
