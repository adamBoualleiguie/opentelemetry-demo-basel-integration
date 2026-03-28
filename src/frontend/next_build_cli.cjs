#!/usr/bin/env node
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

require('./bazel_next_worker_shim.cjs')

const path = require('path')
const nextRoot = path.dirname(require.resolve('next/package.json'))
const nextBin = path.join(nextRoot, 'dist', 'bin', 'next')
// Turbopack cannot follow rules_js pnpm symlinks in the sandbox; webpack + next.config aliases is stable.
const extra = process.argv.slice(2)
const bazel = Boolean(process.env.BAZEL_COMPILATION_MODE)
const buildArgs = bazel ? ['build', '--webpack'] : ['build']
process.argv = [process.argv[0], nextBin, ...buildArgs, ...extra]
require(nextBin)
