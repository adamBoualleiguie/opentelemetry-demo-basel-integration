// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0
//
// Flat ESLint config (ESLint 9 default). `eslint-config-next@16` exports flat config;
// legacy `.eslintrc` + ESLINT_USE_FLAT_CONFIG=false hits a circular-structure bug in
// @eslint/eslintrc’s schema validator when extending `next/core-web-vitals`.

import tsPlugin from "@typescript-eslint/eslint-plugin";
import coreWebVitals from "eslint-config-next/core-web-vitals";
import reactHooks from "eslint-plugin-react-hooks";

// eslint-plugin-react-hooks@7 enables React Compiler–oriented rules. The demo predates full
// compliance; keep them off until refactors (same practical bar as many Next 15/16 codebases).
const reactCompilerHooksRulesOff = {
  "react-hooks/purity": "off",
  "react-hooks/set-state-in-effect": "off",
  "react-hooks/preserve-manual-memoization": "off",
};

const config = [
  // Generated ts_proto output; do not lint (would require editing generated headers).
  { ignores: ["protos/**"] },
  ...coreWebVitals,
  {
    files: ["**/*.{ts,tsx}"],
    plugins: {
      "@typescript-eslint": tsPlugin,
    },
    rules: {
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
    },
  },
  {
    plugins: {
      "react-hooks": reactHooks,
    },
    rules: {
      ...reactCompilerHooksRulesOff,
      "react-hooks/exhaustive-deps": "warn",
      "no-unused-vars": "off",
      "max-len": [
        "error",
        {
          code: 150,
          ignoreComments: true,
          ignoreTrailingComments: true,
          ignoreUrls: true,
          ignoreStrings: true,
          ignoreTemplateLiterals: true,
        },
      ],
    },
  },
];

export default config;
