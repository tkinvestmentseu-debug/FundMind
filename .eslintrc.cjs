/* eslint-env node */
module.exports = {
  root: true,
  env: { es2022: true, node: true, jest: true },
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: "latest", sourceType: "module", ecmaFeatures: { jsx: true } },
  settings: { react: { version: "detect" } },
  plugins: ["@typescript-eslint", "react", "react-hooks", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "plugin:import/recommended",
    "plugin:import/typescript",
    "prettier"
  ],
  rules: {
    "react/react-in-jsx-scope": "off",
    "import/order": ["warn", { "newlines-between": "always", "alphabetize": { "order": "asc" } }]
  },
  ignorePatterns: ["node_modules/", "android/", "ios/", "dist/", "build/", "coverage/"]
};