#!/usr/bin/env node
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

// Bazel js_test entry: ESLint 9 package.json "exports" hides ./bin/eslint.js from require.resolve.
const path = require('path')
const eslintRoot = path.dirname(require.resolve('eslint/package.json'))
const eslintBin = path.join(eslintRoot, 'bin', 'eslint.js')
process.argv = [process.argv[0], eslintBin, ...process.argv.slice(2)]
require(eslintBin)
