# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""Extra `-I` paths for generated `demo.*` and `grpc/health/v1/*` headers (BCR grpc external is `grpc~` under `bazel-bin/external`)."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")

def _currency_grpc_gen_includes_impl(ctx):
    bin_root = ctx.bin_dir.path
    demo_inc = paths.join(bin_root, "src", "currency")
    health_inc = paths.join(bin_root, "external", "grpc~", "src", "proto")
    return [
        CcInfo(
            compilation_context = cc_common.create_compilation_context(
                includes = depset(direct = [demo_inc, health_inc]),
            ),
        ),
    ]

currency_grpc_gen_includes = rule(
    implementation = _currency_grpc_gen_includes_impl,
)
