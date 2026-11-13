// Add a service worker for processing Web Push notifications:
//
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
//
// self.addEventListener("notificationclick", function(event) {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         let client = clientList[i]
//         let clientPath = (new URL(client.url)).pathname
//
//         if (clientPath == event.notification.data.path && "focus" in client) {
//           return client.focus()
//         }
//       }
//
//       if (clients.openWindow) {
//         return clients.openWindow(event.notification.data.path)
//       }
//     })
//   )
// })

/*
Copyright 2015, 2019, 2020, 2021 Google LLC. All Rights Reserved.
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

// Incrementing OFFLINE_VERSION will kick off the install event and force
// previously cached resources to be updated from the network.
// This variable is intentionally declared and unused.
// Add a comment for your linter if you want:
// eslint-disable-next-line no-unused-vars

const OFFLINE_VERSION = 1;
// El nombre lleva la versión: al subirla se crea un cache nuevo y el
// activate borra los anteriores.
const CACHE_NAME = `offline-v${OFFLINE_VERSION}`;
// Customize this with a different URL if needed.
const OFFLINE_URL = "/offline";

// Puerto del dev server de Vite (ajústalo si usas otro).
const VITE_DEV_PORT = "5173";

// Módulos servidos por el dev server de Vite (otro origen, mismo hostname).
const isViteDev = (url) =>
  url.port === VITE_DEV_PORT && url.origin !== self.location.origin;

// Assets estáticos del mismo origen (producción).
const isStaticAsset = (url) =>
  url.origin === self.location.origin &&
  /\.(?:js|css|woff2?|png|svg|ico)$/.test(url.pathname);

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);

      // Setting {cache: 'reload'} in the new request ensures that the
      // response isn't fulfilled from the HTTP cache; i.e., it will be
      // from the network.
      const res = await fetch(OFFLINE_URL, { cache: "reload" });
      const html = await res.clone().text();
      await cache.put(OFFLINE_URL, res);

      // Assets referenciados por el HTML de /offline: los de producción
      // (mismo origen) y los del dev server de Vite.
      const urls = [
        ...new Set(
          [...html.matchAll(/(?:src|href)=["']([^"']+)["']/g)]
            .map((m) => new URL(m[1], self.location.origin))
            .filter((u) => isViteDev(u) || isStaticAsset(u))
            .map((u) => u.href),
        ),
      ];

      console.log("Assets a precachear:", urls);
      await Promise.all(
        urls.map((u) =>
          cache.add(u).catch((e) => console.warn("No se pudo cachear", u, e)),
        ),
      );
    })()
  );
  // Force the waiting service worker to become the active service worker.
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      // Borra los caches de versiones anteriores.
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)),
      );

      // Enable navigation preload if it's supported.
      // See https://developers.google.com/web/updates/2017/02/navigation-preload
      if ("navigationPreload" in self.registration) {
        await self.registration.navigationPreload.enable();
      }
    })()
  );

  // Tell the active service worker to take control of the page immediately.
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Dev: módulos del dev server de Vite. Primero la red (para ver siempre
  // tus cambios) y, si no hay red, la última copia guardada.
  if (isViteDev(url)) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(CACHE_NAME);
        try {
          const response = await fetch(request);
          if (response.ok) cache.put(request, response.clone());
          return response;
        } catch {
          // ignoreSearch: Vite agrega ?v=hash y ?t=timestamp a las URLs.
          const cached = await cache.match(request, {
            ignoreSearch: true,
            ignoreVary: true,
          });
          return cached || Response.error();
        }
      })()
    );
    return;
  }

  // Assets estáticos del mismo origen: primero el cache, luego la red
  if (isStaticAsset(url)) {
    event.respondWith(
      (async () => {
        const cached = await caches.match(request, { ignoreSearch: true });
        if (cached) return cached;

        const response = await fetch(request);
        if (response.ok) {
          const cache = await caches.open(CACHE_NAME);
          cache.put(request, response.clone());
        }
        return response;
      })()
    );
    return;
  }

  // Only call event.respondWith() if this is a navigation request
  // for an HTML page.
  if (request.mode === "navigate") {
    event.respondWith(
      (async () => {
        try {
          // First, try to use the navigation preload response if it's
          // supported.
          const preloadResponse = await event.preloadResponse;
          if (preloadResponse) {
            return preloadResponse;
          }

          // Always try the network first.
          const networkResponse = await fetch(request);

          // Si el servidor está caído y Nginx responde 502/503/504,
          // también mostramos la página offline.
          if ([502, 503, 504].includes(networkResponse.status)) {
            const cache = await caches.open(CACHE_NAME);
            const cachedResponse = await cache.match(OFFLINE_URL);
            return cachedResponse || networkResponse;
          }

          return networkResponse;
        } catch (error) {
          // catch is only triggered if an exception is thrown, which is
          // likely due to a network error.
          // If fetch() returns a valid HTTP response with a response code in
          // the 4xx or 5xx range, the catch() will NOT be called.
          console.log("Fetch failed; returning offline page instead.", error);

          const cache = await caches.open(CACHE_NAME);
          const cachedResponse = await cache.match(OFFLINE_URL);

          // Si por algún motivo /offline no está en el cache, respondemos
          // algo mínimo en vez de dejar la página de error del navegador.
          return (
            cachedResponse ||
            new Response("<h1>Sin conexión</h1>", {
              status: 503,
              headers: { "Content-Type": "text/html; charset=utf-8" },
            })
          );
        }
      })()
    );
  }

  // If our if() condition is false, then this fetch handler won't
  // intercept the request. If there are any other fetch handlers
  // registered, they will get a chance to call event.respondWith().
  // If no fetch handlers call event.respondWith(), the request
  // will be handled by the browser as if there were no service
  // worker involvement.
});
