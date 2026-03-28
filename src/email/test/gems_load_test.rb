# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Smoke test for Bazel: Bundler + Sinatra API (do not `require "sinatra"` here — classic mode
# would start a web server and block until timeout).
require "bundler/setup"
require "sinatra/base"
puts "email_gems_smoke_ok"
