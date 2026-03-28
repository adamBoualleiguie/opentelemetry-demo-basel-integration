#!/usr/bin/env python3

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

"""Bazel entrypoint mirroring Docker `ENTRYPOINT ["locust", "--skip-log-setup"]`."""

from __future__ import annotations

import os
import sys


def main() -> None:
    root = os.path.dirname(os.path.abspath(__file__))
    os.chdir(root)
    from locust.main import main as locust_main

    sys.argv = ["locust", "--skip-log-setup", "-f", os.path.join(root, "locustfile.py")] + sys.argv[1:]
    locust_main()


if __name__ == "__main__":
    main()
