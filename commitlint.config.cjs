/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [2, 'always', ['sentence-case','start-case','lower-case','camel-case','kebab-case','pascal-case','upper-case']],
  },
};