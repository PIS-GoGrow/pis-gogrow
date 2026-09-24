import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

// Deliberadamente separado de vite.config.ts: ese carga SSR, Inertia y los
// plugins de Rails, que un test de componente no necesita.
//
// El alias se arma con import.meta.url y no con node:path porque el proyecto
// no tiene @types/node instalado, y agregarlo solo para resolver una ruta es
// una dependencia nueva a cambio de nada.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": new URL("./app/javascript", import.meta.url).pathname, // espeja "@/*" de tsconfig
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./app/javascript/test/setup.ts"],
    include: ["app/javascript/**/*.test.{ts,tsx}"],
  },
})
