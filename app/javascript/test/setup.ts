import "@testing-library/jest-dom/vitest"

import { cleanup } from "@testing-library/react"
import { afterEach } from "vitest"

// Sin `globals: true`, RTL no registra su afterEach solo y el DOM de un test
// se arrastra al siguiente.
afterEach(cleanup)

// Los primitivos de Radix (los que usa shadcn/ui) miden el DOM al montarse y
// jsdom no trae ninguna de las dos APIs.
const noop = () => undefined

if (!("ResizeObserver" in globalThis)) {
  globalThis.ResizeObserver = class {
    observe = noop
    unobserve = noop
    disconnect = noop
  }
}

if (!window.matchMedia) {
  window.matchMedia = (query: string): MediaQueryList => ({
    matches: false,
    media: query,
    onchange: null,
    addEventListener: noop,
    removeEventListener: noop,
    addListener: noop,
    removeListener: noop,
    dispatchEvent: () => false,
  })
}
