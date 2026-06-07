import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      // 开发时直接引用 @semi/ui 的源码（支持 Vue SFC 热更新）
      '@semi/ui': resolve(__dirname, '../../packages/ui/src/index.ts')
    }
  },
  server: {
    port: 5173,
    host: true
  }
})
