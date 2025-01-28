// @ts-check
const eslint = require("@eslint/js");
const tseslint = require("typescript-eslint");

module.exports = tseslint.config({
  files: ["./**/*.ts", "./**/*.js"],
  extends: [eslint.configs.recommended, ...tseslint.configs.recommended],
});
