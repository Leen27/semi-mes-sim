import js from '@eslint/js'
import ts from 'typescript-eslint'
import pluginVue from 'eslint-plugin-vue'

const browserGlobals = {
  languageOptions: {
    globals: {
      HTMLCanvasElement: 'readonly',
      performance: 'readonly',
      requestAnimationFrame: 'readonly',
      cancelAnimationFrame: 'readonly',
      console: 'readonly'
    }
  }
}

/**
 * TypeScript 共享 ESLint 配置
 */
export const tsEslintConfig = [
  js.configs.recommended,
  ...ts.configs.recommended,
  browserGlobals,
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-non-null-assertion': 'warn',
      'no-console': 'warn'
    }
  }
]

/**
 * Vue + TypeScript 共享 ESLint 配置
 */
export const vueEslintConfig = [
  js.configs.recommended,
  ...ts.configs.recommended,
  browserGlobals,
  ...pluginVue.configs['flat/recommended'],
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: ts.parser,
        extraFileExtensions: ['.vue']
      }
    }
  },
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-non-null-assertion': 'warn',
      'no-console': 'warn',
      'vue/multi-word-component-names': 'off'
    }
  }
]
