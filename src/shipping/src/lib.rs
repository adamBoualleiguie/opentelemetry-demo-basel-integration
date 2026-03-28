// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

//! Library surface for Bazel `rust_test` (binary stays in `main.rs`).

pub mod telemetry_conf;
pub mod shipping_service;

pub use shipping_service::{get_quote, ship_order};
