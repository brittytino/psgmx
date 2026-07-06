import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const config = [
  ...nextVitals,
  ...nextTs,
  {
    ignores: [
      ".next/**",
      "out/**",
      "build/**",
      "next-env.d.ts",
      "scratch/**",
      "scripts/**/*.js",
      "tests/verify-source.js",
    ],
  },
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/ban-ts-comment": "off",
      "@next/next/no-img-element": "off",
      "react-hooks/exhaustive-deps": "error",
      "react/no-unescaped-entities": "off",
      "react-hooks/rules-of-hooks": "error"
    },
  },
];

export default config;
