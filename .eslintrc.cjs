/** Minimal ESLint for RN/TS */
module.exports = {
  root: true,
  env: { es2022: true, node: true, jest: true },
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier"
  ],
  ignorePatterns: ["dist/", "build/", ".expo/", "logs/", "node_modules/"],
  rules: {
    "@typescript-eslint/no-explicit-any": "off",
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }]
  }
};
