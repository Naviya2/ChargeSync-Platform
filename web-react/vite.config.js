import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const rootDir = path.dirname(fileURLToPath(import.meta.url))

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(rootDir, './src'),
    },
  },
  server: {
    port: 5173,
    // Forward API calls to the ASP.NET Core backend so the browser sees a
    // single origin (no CORS needed in dev). Run the API with `dotnet run`
    // in backend/ — it listens on http://localhost:5035.
    proxy: {
      '/api': {
        target: 'http://localhost:5035',
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
