# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""Reusable OCI packaging for rules_python py_binary (rules_pkg + rules_oci)."""

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load")

def py_binary_oci(name, binary, entrypoint_basename, repo_tag, exposed_ports, visibility = None):
    """Layer = pkg_tar(include_runfiles) under /app; entrypoint /app/<entrypoint_basename>.

    Args:
      name: Prefix for *_layer, *_image, *_load targets.
      binary: Label of the py_binary.
      entrypoint_basename: Executable filename inside the layer (must match py_binary `name`).
      repo_tag: Tag for oci_load (e.g. otel/demo-foo:bazel).
      exposed_ports: List of oci_image exposed_ports (e.g. ["8080/tcp"]).
    """
    pkg_tar(
        name = "%s_layer" % name,
        srcs = [binary],
        include_runfiles = True,
        package_dir = "app",
    )

    oci_image(
        name = "%s_image" % name,
        base = "@python_312_slim_bookworm_linux_amd64//:python_312_slim_bookworm_linux_amd64",
        entrypoint = ["/app/%s" % entrypoint_basename],
        exposed_ports = exposed_ports,
        tars = [":%s_layer" % name],
        visibility = visibility or ["//visibility:public"],
        workdir = "/app",
    )

    oci_load(
        name = "%s_load" % name,
        image = ":%s_image" % name,
        repo_tags = [repo_tag],
    )
