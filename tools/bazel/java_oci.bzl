# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""OCI packaging for java_binary deploy JARs (rules_pkg + rules_oci, distroless Java base)."""

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load")

def java_deploy_jar_oci(name, deploy_jar, jar_name, base, repo_tag, exposed_ports = None, visibility = None):
    """Layer = deploy JAR under /usr/src/app; entrypoint `java -jar /usr/src/app/<jar_name>`.

    Args:
      name: Prefix for *_layer, *_image, *_load targets (avoid clashing with java_binary `name`).
      deploy_jar: Label of the implicit `java_binary` deploy output (e.g. `:ad_deploy.jar`).
      jar_name: Basename of the JAR inside the image (must match the file placed by `pkg_tar`).
      base: Label of the digest-pinned distroless Java base (linux/amd64 variant).
      repo_tag: Tag for oci_load (e.g. otel/demo-ad:bazel).
      exposed_ports: Optional list for oci_image exposed_ports (e.g. ["9555/tcp"]); omit for workers with no HTTP.
    """
    pkg_tar(
        name = "%s_layer" % name,
        srcs = [deploy_jar],
        package_dir = "usr/src/app",
    )

    oci_image(
        name = "%s_image" % name,
        base = base,
        entrypoint = ["/usr/bin/java", "-jar", "/usr/src/app/%s" % jar_name],
        exposed_ports = exposed_ports or [],
        tars = [":%s_layer" % name],
        visibility = visibility or ["//visibility:public"],
        workdir = "/usr/src/app",
    )

    oci_load(
        name = "%s_load" % name,
        image = ":%s_image" % name,
        repo_tags = [repo_tag],
    )
