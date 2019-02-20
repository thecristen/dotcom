module.exports = {
  extends: ["airbnb", "prettier"],
  parserOptions: {
    ecmaVersion: 6,
    sourceType: "module"
  },
  plugins: ["prettier", "react-hooks"],
  rules: {
    "prettier/prettier": "error",
    "react/jsx-filename-extension": [1, { extensions: [".tsx"] }],
    "react/prop-types": "off",
    "react-hooks/rules-of-hooks": "error"
  },
  env: {
    browser: true,
    jest: true
  },
  globals: {
    google: "readonly"
  },
  // Eslint config for Typescript files (merges with above)
  overrides: [
    {
      files: ["**/*.ts", "**/*.tsx"],
      parser: "eslint-plugin-typescript/parser",
      plugins: ["typescript"],
      rules: {
        // Turn this rule off since it errors falsely with Typescript imports, it'd be caught by the build anyway
        "import/no-unresolved": "off",
        // Below is pasted from eslint-plugin-typescript recommended.json (overrides doesn't support extend at this time)
        "typescript/adjacent-overload-signatures": "error",
        "typescript/array-type": "error",
        "typescript/ban-types": "error",
        camelcase: "off",
        "typescript/camelcase": "error",
        "typescript/class-name-casing": "error",
        "typescript/explicit-function-return-type": "warn",
        "typescript/explicit-member-accessibility": "error",
        indent: "off",
        // Modified. To match prettier identation rules
        "typescript/indent": ["2", "error"],
        "typescript/interface-name-prefix": "error",
        "typescript/member-delimiter-style": "error",
        "typescript/no-angle-bracket-type-assertion": "error",
        "no-array-constructor": "off",
        "typescript/no-array-constructor": "error",
        "typescript/no-empty-interface": "error",
        "typescript/no-explicit-any": "warn",
        "typescript/no-inferrable-types": "error",
        "typescript/no-misused-new": "error",
        "typescript/no-namespace": "error",
        // Modified. This would disallow the ! postfix operator (non-null-assertion operator), seems like overkill - MH
        "typescript/no-non-null-assertion": "off",
        "typescript/no-object-literal-type-assertion": "error",
        "typescript/no-parameter-properties": "error",
        "typescript/no-triple-slash-reference": "error",
        "no-unused-vars": "off",
        "typescript/no-unused-vars": "warn",
        "typescript/no-use-before-define": "error",
        "typescript/no-var-requires": "error",
        "typescript/prefer-interface": "error",
        "typescript/prefer-namespace-keyword": "error",
        "typescript/type-annotation-spacing": "error"
      }
    }
  ]
};
