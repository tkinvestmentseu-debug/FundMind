/** @type {import('lint-staged').Configuration} */
module.exports = {
  "*.{ts,tsx,js,jsx}": ["eslint --fix"],
  "*.{ts,tsx,js,jsx,json,md,yml,yaml}": ["prettier --write"]
};