import { defineConfig } from 'vite'

export const sharedViteConfig = defineConfig({
  resolve: {
    conditions: ['development', 'browser']
  },
  build: {
    target: 'es2022',
    sourcemap: true
  }
})
