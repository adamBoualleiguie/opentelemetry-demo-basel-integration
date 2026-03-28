# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""React Native / Expo Android: copy tree, npm ci, assembleDebug with hermetic ANDROID_SDK_ROOT + JAVA_HOME."""

def _rel_under_package(pkg, f):
    sp = f.short_path
    prefix = pkg + "/"
    if sp.startswith(prefix):
        return sp[len(prefix):]
    return f.basename

def _rn_android_debug_apk_impl(ctx):
    out = ctx.actions.declare_file("app-debug.apk")
    pkg = ctx.label.package
    sdk_marker = ctx.file._sdk_root

    manifest_lines = []
    inputs = [sdk_marker]
    for f in ctx.files.srcs:
        manifest_lines.append("%s\t%s" % (f.path, _rel_under_package(pkg, f)))
        inputs.append(f)

    manifest = ctx.actions.declare_file(ctx.attr.name + "_manifest.txt")
    ctx.actions.write(
        output = manifest,
        content = "\n".join(manifest_lines) + "\n",
    )
    inputs.append(manifest)

    ctx.actions.run_shell(
        mnemonic = "RnAndroidAssembleDebug",
        outputs = [out],
        inputs = depset(direct = inputs),
        command = """
set -euo pipefail
SDK_BUNDLE="$(dirname "{marker}")"
export JAVA_HOME="$SDK_BUNDLE/jdk"
export ANDROID_SDK_ROOT="$SDK_BUNDLE/sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export GRADLE_USER_HOME="$(mktemp -d)"
export NPM_CONFIG_CACHE="$(mktemp -d)"
trap 'rm -rf "$GRADLE_USER_HOME" "$NPM_CONFIG_CACHE" "$ROOT"' EXIT
ROOT="$(mktemp -d)"
mkdir -p "$ROOT"
while IFS=$(printf '\\t') read -r src dst || [ -n "$src" ]; do
  [ -z "$src" ] && continue
  d="$ROOT/$(dirname "$dst")"
  mkdir -p "$d"
  cp "$src" "$ROOT/$dst"
done < {manifest}
cd "$ROOT"
if ! command -v node >/dev/null 2>&1; then
  echo "node not found on PATH; install Node.js 20+ (see src/react-native-app/README.md)." >&2
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found on PATH." >&2
  exit 1
fi
npm ci --no-audit --no-fund
chmod +x android/gradlew
cd android
./gradlew --no-daemon :app:assembleDebug
cp app/build/outputs/apk/debug/app-debug.apk "{out_apk}"
""".format(
            manifest = manifest.path,
            marker = sdk_marker.path,
            out_apk = out.path,
        ),
        progress_message = "Gradle assembleDebug %s" % ctx.label,
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(files = depset([out])),
        OutputGroupInfo(default = depset([out])),
    ]

rn_android_debug_apk = rule(
    implementation = _rn_android_debug_apk_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True, doc = "RN app tree (no node_modules; no ios/)."),
        "_sdk_root": attr.label(
            default = "@rn_android_sdk//:root",
            allow_single_file = True,
            doc = "Marker file in the hermetic SDK bundle (@rn_android_sdk).",
        ),
    },
    doc = "Produces app-debug.apk via ./gradlew :app:assembleDebug. Uses hermetic JDK + Android SDK from @rn_android_sdk. Requires host node/npm; tags should include requires-network and no-sandbox.",
)
