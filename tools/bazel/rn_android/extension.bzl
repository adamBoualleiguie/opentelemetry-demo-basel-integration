# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

load(":sdk_repo.bzl", "rn_android_sdk_repository")

def _rn_android_sdk_mod_impl(_mctx):
    rn_android_sdk_repository(name = "rn_android_sdk")

rn_android_sdk = module_extension(
    implementation = _rn_android_sdk_mod_impl,
    doc = "Hermetic @rn_android_sdk (JDK + Android SDK) for //src/react-native-app Android Gradle builds.",
)
