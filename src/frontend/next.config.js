// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

/** @type {import('next').NextConfig} */

const dotEnv = require('dotenv');
const dotenvExpand = require('dotenv-expand');
const path = require('path');
const { resolve } = path;

const myEnv = dotEnv.config({
  path: resolve(__dirname, '../../.env'),
});
dotenvExpand.expand(myEnv);

// Under Bazel, `js_run_binary` sets BAZEL_* env vars. A fixed `turbopack.root` breaks Next 16’s
// Turbopack project path vs `.next` (panic: distDirRoot navigates out of projectPath).
const isBazelBuild = Boolean(process.env.BAZEL_COMPILATION_MODE);

const {
  AD_ADDR = '',
  CART_ADDR = '',
  CHECKOUT_ADDR = '',
  CURRENCY_ADDR = '',
  PRODUCT_CATALOG_ADDR = '',
  PRODUCT_REVIEWS_ADDR = '',
  RECOMMENDATION_ADDR = '',
  SHIPPING_ADDR = '',
  ENV_PLATFORM = '',
  OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = '',
  OTEL_SERVICE_NAME = 'frontend',
  PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = '',
} = process.env;

const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  compiler: {
    styledComponents: true,
  },
  // Turbopack: under Bazel use `{}` only — `root: __dirname` panics (distDirRoot vs projectPath).
  // Outside Bazel, pin root so the monorepo lockfile does not confuse resolution.
  turbopack: isBazelBuild
    ? {}
    : {
        root: __dirname,
      },
  // Webpack: used for `next build --webpack` under Bazel (Turbopack + pnpm symlinks panic / mis-resolve).
  webpack: (config, { isServer }) => {
    if (isBazelBuild) {
      // Single React resolution across workers (rules_js symlinks can load two copies → "extends undefined").
      const reactRoot = path.dirname(require.resolve('react/package.json', { paths: [__dirname] }));
      const reactDomRoot = path.dirname(require.resolve('react-dom/package.json', { paths: [__dirname] }));
      config.resolve.alias = {
        ...(config.resolve.alias || {}),
        react: reactRoot,
        'react-dom': reactDomRoot,
      };
    }
    if (!isServer) {
      config.resolve.fallback.http2 = false;
      config.resolve.fallback.tls = false;
      config.resolve.fallback.net = false;
      config.resolve.fallback.dns = false;
      config.resolve.fallback.fs = false;
    }

    return config;
  },
  env: {
    AD_ADDR,
    CART_ADDR,
    CHECKOUT_ADDR,
    CURRENCY_ADDR,
    PRODUCT_CATALOG_ADDR,
    PRODUCT_REVIEWS_ADDR,
    RECOMMENDATION_ADDR,
    SHIPPING_ADDR,
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT,
    NEXT_PUBLIC_PLATFORM: ENV_PLATFORM,
    NEXT_PUBLIC_OTEL_SERVICE_NAME: OTEL_SERVICE_NAME,
    NEXT_PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT,
  },
  images: {
    loader: "custom",
    loaderFile: "./utils/imageLoader.js"
  }
};

module.exports = nextConfig;
