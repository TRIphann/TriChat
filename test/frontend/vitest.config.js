import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: ['./setup.js'],
    include: ['**/*.test.js'],
    css: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['../../frontend/src/**'],
      exclude: [
        'node_modules/',
        '**/*.config.js',
        '**/main.jsx',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '../../frontend/src'),
      'react': path.resolve(__dirname, '../../frontend/node_modules/react'),
      'react-dom': path.resolve(__dirname, '../../frontend/node_modules/react-dom'),
      'zustand': path.resolve(__dirname, '../../frontend/node_modules/zustand'),
      '@testing-library/react': path.resolve(__dirname, '../../frontend/node_modules/@testing-library/react'),
      '@testing-library/jest-dom': path.resolve(__dirname, '../../frontend/node_modules/@testing-library/jest-dom'),
      '@testing-library/user-event': path.resolve(__dirname, '../../frontend/node_modules/@testing-library/user-event'),
      'firebase/app': path.resolve(__dirname, '../../frontend/node_modules/firebase/app'),
      'firebase/auth': path.resolve(__dirname, '../../frontend/node_modules/firebase/auth'),
      'firebase/firestore': path.resolve(__dirname, '../../frontend/node_modules/firebase/firestore'),
      'firebase/storage': path.resolve(__dirname, '../../frontend/node_modules/firebase/storage'),
      'firebase/messaging': path.resolve(__dirname, '../../frontend/node_modules/firebase/messaging'),
    },
  },
});
