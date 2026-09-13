# Guía de Trabajo con el Repositorio

> Grupo 2 · Proyecto de Ingeniería de Software 2026 · Coach: María Freira · Empresa: GoGrow
>
> Transcripción de «Guía de Trabajo con el Repositorio_v2_2026-09-04.pdf». Cambios respecto al PDF: se omite la carátula con los datos personales del equipo; las capturas de GitHub se describen como pasos; la sección 1.2 menciona las credenciales de Google, que se agregaron después al `.env.example`; la sección 3.1 ya no aclara «una vez que ese archivo exista», porque la plantilla de PR ya está en el repo.

## Introducción

Esta guía es el complemento operativo de la [Guía sobre la Gestión de la Configuración v3.0](guia-scm.md). Mientras esa guía explica **qué se decidió y por qué**, esta explica **cómo se hace el día a día** trabajando en el repositorio. Está dirigida al equipo de desarrollo.

## 1. Setup inicial (una sola vez por integrante)

### 1.1 Clonar el repositorio

```bash
git clone https://github.com/PIS-gogrow/pis-gogrow
cd pis-gogrow
```

### 1.2 Configurar variables de entorno

El repositorio incluye un archivo `.env.example` con la estructura de variables necesarias para la aplicación (configuración de Vite, Sentry, autenticación de paneles internos y credenciales del login con Google), sin valores reales. Copialo y completalo:

```bash
cp .env.example .env
```

Los valores reales de estas variables se comparten por Slack en mensaje directo, nunca por el repositorio ni por canales grupales.

> **Nota:** las credenciales de PostgreSQL para el entorno de desarrollo local no están en `.env`: ya vienen fijadas en `docker-compose.yml`, porque no se consideran secreto (el ambiente no es accesible fuera de tu máquina). No hace falta pedirlas ni configurarlas.

### 1.3 Levantar el entorno con Docker Compose

> **Nota:** para este paso necesitás tener configurado Docker. Para eso seguí la [Guía Docker](guia-docker.md).

Para levantar el entorno:

```bash
docker compose up --build
```

Esto construye la imagen a partir de `Dockerfile.dev` (no el `Dockerfile` de producción, que usa Kamal) y levanta dos contenedores: `web` (Rails + Vite) y `db` (PostgreSQL). No hace falta instalar Ruby, Rails ni PostgreSQL en tu máquina.

Verificá que se levantó bien entrando a <http://localhost:3001/>. El detalle completo de verificación, puertos y troubleshooting está en la [Guía Docker](guia-docker.md).

## 2. Flujo día a día: trabajar en un ítem del backlog

### 2.1 Actualizar develop antes de arrancar

Siempre, antes de crear una rama nueva, asegurate de tener la última versión de `develop`:

```bash
git checkout develop
git pull origin develop
```

Saltarse este paso es la causa más común de conflictos grandes más adelante: si empezás desde una versión vieja de `develop`, tu rama se va a alejar más de lo necesario.

### 2.2 Crear la rama del ítem

Formato: `feature/<id-del-item>-<descripcion-corta>`

```bash
git checkout -b feature/23-login-usuario
```

Ejemplos:

```
feature/23-login-usuario
feature/47-listado-empleados
```

La primera vez que pusheás una rama nueva, Git te va a pedir que indiques el remoto explícitamente:

```bash
git push -u origin feature/23-login-usuario
```

Después de esa primera vez, un `git push` normal alcanza para esa misma rama: el vínculo con el remoto (llamado *upstream*) queda configurado automáticamente.

Cada rama pertenece a la persona que la crea. Nadie más la toca directamente.

### 2.3 Trabajar y commitear seguido

Hacé commit cada vez que termines algo concreto: no al final del día, no «cuando hay suficiente código». Commits chicos y frecuentes facilitan encontrar dónde se rompió algo y hacen que trabajar en la rama sea más cómodo.

> **Importante:** el mensaje de estos commits internos no tiene que seguir Conventional Commits estrictamente, porque esos commits se van a aplastar en uno solo cuando hagas Squash and Merge ([sección 4.3](#43-qué-pasa-al-mergear-squash-and-merge)). Lo que sí tiene que seguir el formato es el título del Pull Request ([sección 3.2](#32-titular-el-pr-con-conventional-commits)), porque es lo que va a quedar como mensaje definitivo en `develop`.

```bash
git add .
git commit -m "login funcionando con validación básica"
git commit -m "arreglo bug en el form"
git commit -m "agrego tests"
```

Dicho esto, es buena práctica igual escribir mensajes descriptivos: te ayuda a vos mismo si tenés que volver atrás mientras trabajás.

### 2.4 Mantener la rama actualizada

Si mientras trabajás otros compañeros mergearon cambios a `develop`, conviene incorporarlos para no alejarte demasiado. Esto reduce el tamaño de los conflictos cuando llegue el momento de mergear:

```bash
git fetch origin
git rebase origin/develop
```

Si el rebase genera conflictos, Git te va a avisar en qué archivos. Resolvés cada uno, hacés `git add <archivo>` y continuás con `git rebase --continue`.

> **Ojo:** si ya habías pusheado esta rama antes de rebasear, vas a necesitar force-push después (ver [5.2](#52-conflictos-al-hacer-rebase)). Esto es normal y esperado en tu propia rama. Nunca hagas force-push sobre `develop` o `main`.

## 3. Abrir un Pull Request

### 3.1 Pedir revisión (Pull Request)

**Push de la rama:**

```bash
git push origin feature/23-login-usuario
```

**Creación del PR:**

1. En la interfaz del repositorio en GitHub, andá a la pestaña **Pull requests**.
2. Seleccioná **New pull request**.
3. **Este es el paso importante.** En la pantalla de «Comparing changes» hay dos selectores:
   - **base:** la rama de destino, donde querés que se integre tu cambio. Para un feature normal, siempre es `develop`, nunca `main`.
   - **compare:** tu rama de trabajo, la que tiene los commits que hiciste; por ejemplo, `feature/23-login-usuario`.

   El selector debería quedar así:

   ```
   base: develop ← compare: feature/23-login-usuario
   ```

   Después apretá **Create pull request** (todavía no lo crea).

   > **Nota:** si dejás `base: main`, le estarías pidiendo a GitHub que compare y mergee directo contra `main`, saltando `develop` por completo. Eso rompería todo el flujo definido en la guía de SCM (nadie va a `main` salvo en el cierre de iteración).

4. En el formulario «Open a pull request»:
   1. **Completar el título.** Acá va el texto que tiene que cumplir Conventional Commits ([sección 3.2](#32-titular-el-pr-con-conventional-commits)):

      ```
      feat(auth): agregar login con email y contraseña
      ```

      Este campo es el que el Action de Lint PR Title va a validar apenas confirmes.
   2. **Completar la descripción.** GitHub la precarga con el contenido de [`.github/pull_request_template.md`](../.github/pull_request_template.md). Ahí completás los cuatro campos: qué se hizo, cómo probarlo, ítem relacionado y checklist ([sección 3.3](#33-completar-la-plantilla-del-pr)).
   3. **Asignar revisor.** En el panel derecho del formulario, buscá la sección **Reviewers** y asigná a un compañero (no a vos mismo).
   4. **Click en «Create pull request» (confirmar).** Ahí sí se crea el PR. A partir de ese momento empiezan a correr los checks automáticos (branch protection, lint del título).

### 3.2 Titular el PR con Conventional Commits

El título del PR es lo más importante de este paso: es el texto que un Action va a validar automáticamente, y es el mensaje que va a quedar como commit definitivo en `develop` después del squash.

Formato: `<tipo>(<alcance>): <descripción breve>`

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Se agrega una funcionalidad nueva. |
| `fix` | Se corrige un bug. |
| `refactor` | Se reorganiza código sin cambiar comportamiento. |
| `test` | Se agregan o modifican tests. |
| `docs` | Se modifica documentación. |
| `chore` | Mantenimiento (dependencias, configuración, etc.). |
| `style` | Cambios de formato que no afectan la lógica. |

**Ejemplos correctos:**

```
feat(auth): agregar login con email y contraseña
fix(empleados): corregir filtro de búsqueda por nombre
refactor(db): extraer lógica de consultas a un service object
```

**Ejemplos incorrectos (van a fallar el check):**

| Título | Problema |
|---|---|
| `Agrego login de usuario` | Falta el tipo y los dos puntos |
| `Login` | No dice qué tipo de cambio es |
| `FEAT: agregar login` | El tipo va en minúscula |
| `feat: Login de usuario` | Evitar mayúscula al inicio de la descripción |

### 3.3 Completar la plantilla del PR

Al abrir el PR, GitHub va a precargar la descripción con la plantilla del repositorio. Completá los cuatro campos:

```markdown
## Qué se hizo
<!-- Descripción breve del cambio -->

## Cómo probarlo
<!-- Pasos para verificar que funciona -->

## Ítem relacionado
<!-- Link o ID del ítem en ClickUp -->

## Checklist
- [ ] Tests agregados/actualizados
- [ ] Sin warnings de linter
- [ ] Probado localmente con Docker Compose
```

Ejemplo completo:

```markdown
## Qué se hizo
Se agregó el formulario de login con validación de email y contraseña
contra la base de datos.

## Cómo probarlo
1. docker compose up
2. Ir a /login
3. Probar con un usuario existente y uno inexistente

## Ítem relacionado
ClickUp #23

## Checklist
- [x] Tests agregados/actualizados
- [x] Sin warnings de linter
- [x] Probado localmente con Docker Compose
```

A diferencia del título, esto no lo valida ningún Action: depende de la disciplina de cada uno. Un PR sin esta información completa hace perder tiempo al revisor, que tiene que preguntar por Slack lo que debería estar escrito acá.

## 4. Qué esperar del proceso de revisión

### 4.1 Si el check de título falla

Vas a ver algo así al pie del PR:

```
❌ Lint PR Title / lint-pr-title — Failed
No release type found in pull request title.
```

El botón de merge va a estar deshabilitado. **No hace falta tocar código ni commits:** corregís el título del PR directamente en GitHub (click en el título → editar) y el check se vuelve a correr solo.

### 4.2 Si el compañero revisor pide cambios

Hacés los cambios en tu rama local, commiteás normal y pusheás. No hace falta abrir un PR nuevo, se actualiza el mismo:

```bash
git add .
git commit -m "ajusto validación según comentarios"
git push origin feature/23-login-usuario
```

### 4.3 Qué pasa al mergear (Squash and Merge)

Cuando el PR está aprobado y todos los checks pasan, el merge se hace con **Squash and Merge**. Esto junta todos tus commits internos en uno solo, usando el **título del PR** como mensaje. Tus commits de trabajo («arreglo bug», «wip», etc.) desaparecen: no importa cómo trabajaste puertas adentro de tu rama, lo único que queda en `develop` es un commit prolijo por ítem.

Después del merge, la rama se puede eliminar (GitHub lo ofrece automáticamente).

## 5. Casos especiales / troubleshooting

### 5.1 Revisar el PR de un compañero sin perder tu trabajo (worktrees)

Si estás en medio de algo y necesitás revisar el código de otro sin hacer *stash* ni commitear algo a medias:

```bash
git worktree add ../revision-login feature/23-login-usuario
# revisás en esa carpeta separada
git worktree remove ../revision-login
```

El worktree es una carpeta aparte que comparte el historial del repo, pero tiene su propio estado de archivos.

### 5.2 Conflictos al hacer rebase

Si `git rebase origin/develop` ([sección 2.4](#24-mantener-la-rama-actualizada)) te tira conflictos:

1. Git te muestra qué archivos están en conflicto.
2. Los abrís, buscás las marcas `<<<<<<<`, `=======`, `>>>>>>>` y dejás el código correcto.
3. `git add <archivo>` por cada uno resuelto.
4. `git rebase --continue`
5. Si ya habías pusheado la rama antes: `git push --force-with-lease origin feature/23-login-usuario`

Usá siempre `--force-with-lease` y no `--force` a secas: evita sobreescribir cambios que otro haya pusheado a tu rama sin que te enteres (poco común, pero puede pasar si dos personas tocan la misma rama).

### 5.3 El check de CI falla por otra razón (tests, linter)

Si además del check de título hay tests o linter configurados como status checks obligatorios, un fallo ahí sí requiere tocar código, no solo el título:

1. Entrá a la pestaña **Checks** del PR y mirá el log del que falló.
2. Corregí el problema localmente y corré el mismo comando en tu máquina para confirmar.
3. Commit y push normal: el check se vuelve a correr solo.

## 6. Cierre de iteración (Responsable de SCM)

Esta sección aplica solo al Responsable de Gestión de la Configuración, al cierre de cada iteración, una vez que el incremento fue verificado internamente:

```bash
git checkout main
git merge develop
git tag v2025-11-03
git push origin main --tags
```

El tag marca exactamente qué código fue entregado en esa iteración. Después del push, se dispara el deploy a producción en AWS (o se hace manualmente, según cómo quede definida esa parte con el cliente). La URL de producción es la que se comparte con el cliente para que revise el incremento: su feedback alimenta la siguiente iteración, no bloquea este cierre.

## 7. Configuración de checks automáticos y branch protection (Responsable de SCM)

Esta sección aplica una sola vez, al configurar el repositorio, y es responsabilidad del Responsable de Gestión de la Configuración. El resto del equipo no necesita repetir estos pasos: una vez configurados, aplican automáticamente a todos los Pull Requests.

Esta configuración ya fue aplicada sobre el repositorio real (`pis-gogrow`, bajo la organización). Esta sección queda como referencia de cómo se hizo y para el caso de que haya que reconfigurar algo (por ejemplo, si se agrega un nuevo status check obligatorio más adelante).

### 7.1 Chequeo automático del título del PR

Se agrega un archivo al repositorio que valida, mediante GitHub Actions, que el título de cada Pull Request siga Conventional Commits:

```bash
mkdir -p .github/workflows
```

Contenido de [`.github/workflows/lint-pr-title.yml`](../.github/workflows/lint-pr-title.yml):

```yaml
name: Lint PR Title
on:
  pull_request:
    types: [opened, edited, synchronize]
jobs:
  lint-pr-title:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Este check corre automáticamente a partir de este momento en cada apertura, edición o actualización de un Pull Request. No requiere activación adicional.

### 7.2 Configurar el mensaje de commit del squash

Como el equipo usa Squash and Merge ([sección 4.3](#43-qué-pasa-al-mergear-squash-and-merge)), conviene que el mensaje final del commit tome el título del PR por defecto, en vez de otras opciones (como el detalle de todos los commits internos).

1. En el repositorio, ir a **Settings → General**.
2. Bajar hasta la sección **Pull Requests**.
3. En **Allow squash merging**, abrir el desplegable **Default commit message**.
4. Seleccionar **«Pull request title»**.

Con esto, al mergear, la caja de mensaje del commit de squash viene precargada con el título del PR. Sigue siendo editable en el momento del merge (es una precarga, no un bloqueo), así que corregir el título antes de mergear ([sección 4.1](#41-si-el-check-de-título-falla)) sigue siendo necesario.

### 7.3 Branch protection sobre main y develop

Se configura una regla de protección por cada rama (se repiten los mismos pasos dos veces, una para `main` y otra para `develop`):

1. **Settings → Branches → Add branch protection rule**
2. En **Branch name pattern**, escribir el nombre de la rama (`main` o `develop`).
3. Activar:
   - **Require a pull request before merging:** bloquea el push directo.
   - **Require approvals**, con mínimo **1**: al menos un compañero distinto al autor debe aprobar.
   - **Require status checks to pass before merging:** y dentro de esa opción, marcar el check `lint-pr-title` ([sección 7.1](#71-chequeo-automático-del-título-del-pr)) como obligatorio.
4. Guardar (**Create** o **Save changes**, según la versión de la UI).

A partir de acá, ningún Pull Request puede mergearse a `main` o `develop` sin pasar por revisión y sin que el título cumpla Conventional Commits: la convención queda garantizada por la plataforma, no solo por la disciplina del equipo.
