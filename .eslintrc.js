module.exports = {
  root: true,
  extends: ["expo", "plugin:@typescript-eslint/recommended"],
  plugins: ["@typescript-eslint"],
  ignorePatterns: ["node_modules", "dist"],
  overrides: [
    {
      files: ["app/**/*.{ts,tsx}", "__tests__/**/*.{ts,tsx}"],
      parser: "@typescript-eslint/parser",
      rules: {
        "no-unused-vars": "off",
        "@typescript-eslint/no-unused-vars": ["warn"]
      }
    }
  ]
};
