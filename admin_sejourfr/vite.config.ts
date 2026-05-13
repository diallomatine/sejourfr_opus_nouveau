import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [react()],
    server: {
        port: 3000,
        strictPort: true, // optionnel : échoue si 3000 est pris au lieu de prendre 3001
    },
});