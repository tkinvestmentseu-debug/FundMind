/* eslint.config.mjs - FundMind flat config (ESLint v9) */
/* Minimal TS/TSX parsing for app and tests; ignore backups and build outputs. */
/* No external "expo" config required. */

import tsParser from "@typescript-eslint/parser";
import tsPlugin from "@typescript-eslint/eslint-plugin";

export default [
  {
    ignores: [
      "node_modules/**",
      "dist/**",
      "build/**",
      "coverage/**",
      "android/**",
      "ios/**",
      ".expo/**",
      ".expo-shared/**",
      "backups/**"
    ]
  },
  {
    files: ["app/**/*.{ts,tsx}", "__tests__/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      ecmaVersion: 2021,
      sourceType: "module",
      parserOptions: { ecmaFeatures: { jsx: true } }
    },
    plugins: {
      "@typescript-eslint": tsPlugin
    },
    rules: {
      // keep rules minimal; expand later as needed
    }
  }
];
