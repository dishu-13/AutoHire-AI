const js = require("@eslint/js");
const tseslint = require("typescript-eslint");

module.exports = tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["src/**/*.ts"],
    languageOptions: {
      parserOptions: {
        project: "./tsconfig.json",
        tsconfigRootDir: __dirname
      }
    },
    rules: {
      "max-len": ["error", { "code": 100, "ignoreStrings": true }],
      "object-curly-spacing": ["error", "always"],
      "quotes": ["error", "double"],
      "semi": ["error", "always"]
    }
  }
);
