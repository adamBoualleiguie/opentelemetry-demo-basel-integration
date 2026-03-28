'use strict'
// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

// Next’s static worker pool sizes from os.cpus(). Under rules_js, parallel workers each resolve
// their own module graph and hit duplicate React/styled-components → "Class extends undefined".
// Pretend a single CPU so collection runs effectively serial (same as many CI single-core VMs).
const os = require('os')
const realCpus = os.cpus
os.cpus = () => {
  const list = realCpus.call(os)
  return list.length ? [list[0]] : []
}
