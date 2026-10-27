import js from '@eslint/js';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
export default [
  { ignores: ['node_modules/**', '.next/**', 'public/**', 'output/**', 'app_inventory/**', 'next-env.d.ts'] },
  {
    files: ['**/*.{js,mjs,ts,tsx}'],
    languageOptions: { parser: tsParser, parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } } },
    plugins: { '@typescript-eslint': tsPlugin },
    rules: { ...js.configs.recommended.rules, ...tsPlugin.configs.recommended.rules, 'no-undef': 'off', '@typescript-eslint/no-explicit-any': 'off' },
  },
];
