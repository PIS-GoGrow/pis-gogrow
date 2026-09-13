# Guía Docker v2.0

> Grupo 2 · Proyecto de Ingeniería de Software 2026 · Coach: María Freira · Empresa: GoGrow
>
> Transcripción de «Guía Docker_v2_2026-09-03.pdf». Cambios respecto al PDF: se omite la carátula con los datos personales del equipo; las capturas de Docker Desktop se describen en texto; en la sección 4.3 figura la URL real del repositorio; el Anexo A describe `Dockerfile.dev` (Ruby 4.0.5, código en `/rails`, puerto 3001), que es lo que hoy usa `docker-compose.yml`, en lugar de la imagen `ruby:3.3`, la carpeta `/app` y el puerto 3000 del texto original.

## 1. Introducción

Más detalle en el [Anexo A](#anexo-a-cómo-funciona-docker-en-más-detalle).

**¿Qué es Docker?** Docker es una herramienta que crea entornos de desarrollo aislados en tu computadora. Todo lo que el proyecto necesita (Ruby, Rails, PostgreSQL) vive dentro de Docker, separado de tu sistema operativo.

**¿Por qué lo usamos?** Para que el entorno sea idéntico en todas las máquinas de los integrantes del equipo. Clonás el repo, corrés un comando y tenés todo funcionando sin instalar nada manualmente.

**¿Qué nos soluciona?** Que no tengas que instalar Ruby, Rails ni PostgreSQL en tu máquina. Cuando terminás el proyecto, eliminás las imágenes de Docker y tu sistema queda limpio.

## 2. Repositorio del proyecto

El proyecto se desarrolla en el repositorio `pis-gogrow`, creado por el equipo a partir del repositorio base que proporcionó el cliente (stack ya configurado: Rails + Inertia.js + React + Vite, Authentication Zero, shadcn/ui, Kamal).

**URL del repositorio:** <https://github.com/PIS-gogrow/pis-gogrow.git>

## 3. Instalación y configuración en Windows

¿Usás Mac? Andá a la [sección 4](#4-instalación-y-configuración-en-mac).

### 3.1 Instalar Docker Desktop

1. Entrá a <https://www.docker.com/products/docker-desktop/> y descargá el instalador para Windows. Elegí la opción **AMD64** (es la estándar para cualquier PC o notebook con Windows).
2. Ejecutá el instalador. Cuando te pregunte sobre el backend, dejá marcada la opción de usar **WSL 2**. Es la configuración recomendada para Windows y se instala automáticamente si todavía no la tenés.
3. Una vez instalado, abrí Docker Desktop desde el menú de inicio. Cuando el ícono de la ballena en la barra de tareas quede estático (deja de animarse), Docker está listo.
4. En la pantalla de creación de cuenta, elegí la opción de cuenta personal (**Personal**). Es gratuita y es todo lo que necesitamos para el proyecto.

> **Nota:** si Windows te pide instalar WSL 2 durante el proceso, seguí las instrucciones que aparecen en pantalla. Es automático.

### 3.2 Verificar que Docker funciona

1. Abrí una terminal (PowerShell o Windows Terminal) y corré estos dos comandos:

   ```bash
   docker --version
   docker compose version
   ```

   Tenés que ver los números de versión de cada uno.

> **Nota:** Docker Desktop tiene que estar corriendo para que funcionen los comandos.

### 3.3 Clonar el repositorio

1. Si no tenés Git instalado, descargalo desde <https://git-scm.com/> e instalalo con las opciones por defecto.
2. Elegí la carpeta donde querés tener el proyecto, abrí una terminal ahí y corré:

   ```bash
   git clone https://github.com/PIS-gogrow/pis-gogrow.git
   cd pis-gogrow
   ```

### 3.4 Levantar el entorno

1. Con Docker Desktop corriendo (programa abierto), dentro de la carpeta del proyecto (paso 3.3) corré:

   ```bash
   docker compose up --build
   ```

   La primera vez tarda varios minutos porque Docker tiene que descargar las imágenes de Ruby y PostgreSQL, instalar las gemas, los paquetes de Node y construir el entorno completo. Las veces siguientes es más rápido porque las capas quedan cacheadas.

**Verificación:**

1. Entrá a <http://localhost:3001/up>: tiene que devolver una página en verde con status 200. Es el healthcheck de Rails.
2. Entrá a <http://localhost:3001/>: tiene que aparecer la home real del proyecto (Inertia + React), con los links a Inertia Rails, shadcn/ui, React y Rails.
3. Los assets (CSS, JS) se sirven desde Vite en <http://localhost:5173>: el navegador se los pide directo a ese puerto, así que también tiene que estar accesible.

> **Nota:** el entorno de desarrollo corre sobre `Dockerfile.dev`, no sobre el `Dockerfile` de producción del repositorio (ese último es multi-stage y está pensado para el deploy con Kamal; no se toca para desarrollo local).

### 3.5 Lo que vas a ver en Docker Desktop

Una vez que todo esté corriendo, en Docker Desktop vas a ver:

- **Containers:** el grupo `rails_inertia_base_dev` (nombre fijado en el `docker-compose.yml`) con dos contenedores dentro: `db` (PostgreSQL 17) y `web` (Rails + Vite).
- **Images:** dos imágenes: `postgres:17` y la imagen construida a partir de `Dockerfile.dev`.
- **Volumes:** dos volúmenes nombrados. Uno guarda los datos de Postgres (así la base persiste entre reinicios) y el otro guarda `node_modules` dentro del contenedor `web`. Este segundo existe porque el código del proyecto se monta en vivo (`.:/rails`), y si no hubiera un volumen aparte para `node_modules`, ese montaje taparía los paquetes de Node que se instalaron durante el build de la imagen.

## 4. Instalación y configuración en Mac

### 4.1 Instalar Docker Desktop

1. Entrá a <https://www.docker.com/products/docker-desktop/> y descargá el instalador para Mac. Elegí la opción correcta según tu chip: **Apple Silicon** (M1/M2/M3/M4) si tu Mac es del 2020 en adelante, o **Intel** si es más antigua. Para saber cuál tenés, andá al menú Apple → Acerca de esta Mac y fijate en el procesador.
2. Abrí el archivo `.dmg` descargado y arrastrá Docker a la carpeta Aplicaciones.
3. Abrí Docker desde Aplicaciones. La primera vez te va a pedir permiso para instalar componentes adicionales. Aceptá.
4. Cuando el ícono de la ballena en la barra de menú quede estático, Docker está listo.
5. En la pantalla de creación de cuenta, elegí la opción de cuenta personal (**Personal**). Es gratuita.

### 4.2 Verificar que Docker funciona

1. Abrí una terminal (Terminal.app o iTerm) y corré:

   ```bash
   docker --version
   docker compose version
   ```

   **Verificación:** tenés que ver los números de versión de cada uno.

### 4.3 Clonar el repositorio

1. Abrí una terminal, navegá a la carpeta donde querés el proyecto y corré:

   ```bash
   git clone https://github.com/PIS-gogrow/pis-gogrow.git
   cd pis-gogrow
   ```

### 4.4 Levantar el entorno

1. Con Docker Desktop corriendo, dentro de la carpeta del proyecto corré:

   ```bash
   docker compose up --build
   ```

   La primera vez tarda varios minutos porque Docker tiene que descargar las imágenes de Ruby y PostgreSQL, instalar las gemas, los paquetes de Node y construir el entorno completo. Las veces siguientes es más rápido porque las capas quedan cacheadas.

**Verificación (tres pasos):**

1. Entrá a <http://localhost:3001/up>: tiene que devolver una página en verde con status 200. Es el healthcheck de Rails.
2. Entrá a <http://localhost:3001/>: tiene que aparecer la home real del proyecto (Inertia + React), con los links a Inertia Rails, shadcn/ui, React y Rails.
3. Los assets (CSS, JS) se sirven desde Vite en <http://localhost:5173>: el navegador se los pide directo a ese puerto, así que también tiene que estar accesible.

> **Nota:** el entorno de desarrollo corre sobre `Dockerfile.dev`, no sobre el `Dockerfile` de producción del repositorio (ese último es multi-stage y está pensado para el deploy con Kamal; no se toca para desarrollo local).

## 5. Uso del día a día

**Levantar el entorno**

```bash
docker compose up
```

**Apagar el entorno**

`Ctrl+C` en la terminal donde corre, o desde otra terminal:

```bash
docker compose down
```

**Ver los logs si algo falla**

```bash
docker compose logs web
docker compose logs db
```

**Reconstruir la imagen (si cambia el Dockerfile o el Gemfile)**

```bash
docker compose build
docker compose up
```

**Correr comandos de Rails dentro del contenedor**

Por ejemplo, para correr migraciones o la consola de Rails:

```bash
docker compose exec web bundle exec rails db:migrate
docker compose exec web bundle exec rails console
```

## 6. Preguntas frecuentes

**¿Necesito instalar Ruby o PostgreSQL en mi máquina?**

No. Todo corre dentro de Docker. Tu máquina no necesita tener ninguna de esas dependencias instaladas.

**¿Docker ocupa mucho espacio?**

Las imágenes del proyecto pesan aproximadamente 1,5 GB en total. El consumo de RAM mientras está corriendo es de unos 200-400 MB para el servidor Rails y unos 50 MB para PostgreSQL, lo cual es manejable en cualquier máquina con 8 GB de RAM.

**¿Qué pasa si elimino las imágenes?**

Docker las vuelve a descargar y construir la próxima vez que corrés `docker compose up`. Tu código no se pierde porque vive en tu carpeta local, no dentro de Docker.

**¿Qué pasa si desinstalo Docker Desktop?**

Se eliminan todas las imágenes y contenedores. Tu máquina queda sin ningún rastro de Ruby, Rails ni PostgreSQL. Tu código local sigue intacto porque no vive dentro de Docker.

**Cambié algo en el código y no se refleja en localhost:3001**

Los cambios en archivos de Rails (controladores, vistas, modelos) se reflejan automáticamente sin reiniciar nada. Si cambiaste el `Gemfile` o el `Dockerfile.dev`, necesitás reconstruir la imagen con `docker compose build`.

**El puerto 3001 ya está en uso**

Otro proceso en tu máquina está usando ese puerto. Podés cambiarlo en el `docker-compose.yml`: donde dice `"3001:3000"` cambiá el primer número por otro, por ejemplo `"3002:3000"`, y accedé desde <http://localhost:3002>. El segundo número (3000) no se toca: es el puerto interno donde escucha Rails dentro del contenedor.

Lo mismo puede pasar con el puerto 5173 (Vite): tiene su propio mapeo `"5173:5173"`, independiente del de Rails. Si cambiás uno, no hace falta tocar el otro.

## Anexo A: ¿Cómo funciona Docker en más detalle?

Docker trabaja con dos conceptos centrales. Una **imagen** es la «receta» del entorno: define qué sistema operativo usar, qué programas instalar y cómo configurarlos. Se construye una vez a partir de un Dockerfile que está en el repositorio. Un **contenedor** es una instancia de esa imagen corriendo. Lo podés prender, apagar y eliminar sin que la imagen se vea afectada.

En Docker Desktop podés ver las imágenes en la sección **Images** y los contenedores en **Containers**. Para este proyecto vas a tener dos contenedores: uno para el servidor Rails y otro para la base de datos PostgreSQL.

El entorno de desarrollo está definido en dos archivos dentro del repositorio: `Dockerfile.dev`, que describe cómo construir la imagen del servidor, y `docker-compose.yml`, que orquesta los dos contenedores y define cómo se comunican entre sí. Esto significa que si alguien del equipo cambia la versión de Ruby o agrega un nuevo servicio, todos actualizan corriendo `docker compose build`, sin configuración manual.

Sin Docker, cada integrante tendría que instalar Ruby, Rails, Node.js y PostgreSQL directamente en su máquina, con versiones específicas y el riesgo de que algo funcione en una máquina y no en otra. Con Docker, ese problema desaparece: el entorno es el mismo para todos porque está descrito en código, no en pasos manuales.

Una cosa importante sobre el almacenamiento: si eliminás una imagen, Docker la vuelve a descargar y construir la próxima vez que levantés. Si desinstalás Docker Desktop directamente, se borran todas las imágenes, contenedores y volúmenes. Tu código no se pierde porque vive en tu carpeta local, no dentro de Docker. Tu máquina queda sin ningún rastro de Ruby, Rails ni PostgreSQL.

### Explicación de archivos relevantes

**`Dockerfile.dev`**

Es la receta que le dice a Docker cómo construir la imagen del servidor Rails para desarrollo. Parte de la imagen `ruby:4.0.5-slim` (que ya tiene Ruby instalado), instala las dependencias del sistema (herramientas para compilar gemas, el cliente de PostgreSQL, libvips) y Node.js 24.16.0 para Vite, y define que el código vive en `/rails` dentro del contenedor. Al arrancar el contenedor, prepara la base (`db:prepare`) y levanta Rails y Vite juntos. La imagen se construye una sola vez, y no se vuelve a construir a menos que hagas `docker compose build`.

**`docker-compose.yml`**

Es el archivo que orquesta los dos contenedores del proyecto. Define el servicio `db` (PostgreSQL) y el servicio `web` (Rails + Vite), cómo se comunican entre sí, qué puertos expone cada uno, qué variables de entorno necesitan y qué volúmenes usan.

La línea más importante para el desarrollo es `- .:/rails`, dentro de `volumes`, que monta tu carpeta local dentro del contenedor en tiempo real: cualquier cambio que hacés en el código se refleja instantáneamente sin reiniciar nada.

**`Gemfile` y `Gemfile.lock`**

En Ruby, los paquetes de código se llaman gemas (*gems*). El `Gemfile` declara qué gemas necesita el proyecto y con qué versiones. El `Gemfile.lock` registra las versiones exactas que se instalaron.

Cuando Docker construye la imagen, copia estos dos archivos primero y corre `bundle install` para instalar todas las dependencias antes de copiar el resto del código. Esto es intencional: Docker cachea esa capa, así que si el `Gemfile` no cambió, no reinstala las gemas cada vez que reconstruís, lo que hace el proceso mucho más rápido. Son el equivalente al `package.json` y `package-lock.json` de Node.js.

### Cómo se relacionan entre sí

Cuando corrés `docker compose up` por primera vez, Docker lee el `docker-compose.yml`, ve que el servicio `web` necesita construirse a partir de `Dockerfile.dev`, ejecuta ese Dockerfile (que copia el `Gemfile` e instala las gemas) y luego levanta ambos contenedores. El servicio `web` se conecta al servicio `db` usando el nombre `db` como hostname, que Docker resuelve automáticamente dentro de la red interna que crea entre los contenedores. Desde afuera, accedés al servidor Rails en `localhost:3001` porque el `docker-compose.yml` mapea el puerto 3000 del contenedor al 3001 de tu máquina.

## Versión y changelog

| Versión | Fecha | Cambios |
|---|---|---|
| v1.0 | 2026-08-27 | Versión inicial del documento, basada en repositorio temporal de prueba. |
| v2.0 | 2026-09-02 y 2026-09-03 | Se reemplaza el repositorio temporal por el repositorio real del proyecto (`pis-gogrow`). Se documenta `Dockerfile.dev` como imagen separada del `Dockerfile` de producción. Se agrega el puerto de Vite (5173) y el volumen nombrado de `node_modules`. Se actualizan versiones de Ruby (4.0.5), Node (24.16.0) y PostgreSQL (17). Se elimina el Anexo B (Inertia.js ya integrado). Se documenta la corrección de line-endings en `.gitattributes`. El 2026-09-03 se añadió la URL en vez de `<url-de-pis-gogrow>` y en la primera parte de la verificación se corrigió que la pantalla que se despliega es verde. |
