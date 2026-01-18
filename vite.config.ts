import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true
  },
  optimizeDeps: {
    include: [
      'mammoth',
      'turndown',
      'marked',
      'docx',
      'file-saver',
      '@logicflow/core',
      '@logicflow/extension'
    ]
  }
})
