import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:5244',
        changeOrigin: true,
        secure: false,
      },
      '/hubs': {
        target: 'http://localhost:5244',
        changeOrigin: true,
        ws: true,
        secure: false,
      },
    },
  },
  build: {
    target: 'es2022',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          firebase: ['firebase/app', 'firebase/auth', 'firebase/messaging'],
          signalr: ['@microsoft/signalr'],
          agora: ['agora-rtc-sdk-ng'],
          maps: ['leaflet', 'react-leaflet'],
        },
      },
    },
  },
});
