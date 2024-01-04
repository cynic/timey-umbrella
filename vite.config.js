import { defineConfig } from 'vite';
import elmPlugin from 'vite-plugin-elm';

export default defineConfig({
  plugins: [elmPlugin()],
  server: {
    // Configure server options if needed
  },
  // Add other Vite configurations if required
});