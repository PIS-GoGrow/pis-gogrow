# Guía sobre la Gestión de la Configuración v3.0

> Grupo 2 · Proyecto de Ingeniería de Software 2026 · Coach: María Freira · Empresa: GoGrow
>
> Transcripción de «Guia SCM_v3_2026-09-01.pdf». Cambios respecto al PDF: se omite la carátula con los datos personales del equipo; las referencias a otras guías son enlaces; en la sección 2.8 figura el nombre real del archivo de la plantilla, y en la sección 5 el `.env.example` incluye las variables de Google que se agregaron después.

## 1. Introducción

Este documento describe las decisiones tomadas en materia de Gestión de la Configuración para el proyecto Go Grow, desarrollado en el marco de la materia Proyecto de Ingeniería de Software (FING, UdelaR). Está dirigido tanto al equipo de desarrollo como a la cátedra.

El objetivo es establecer, desde el inicio del proyecto, las convenciones y herramientas que el equipo va a usar para versionar el código, organizar el trabajo en Git, gestionar el entorno de desarrollo y coordinar las entregas al cliente.

Algunas decisiones quedan pendientes de confirmación con el cliente y se indican explícitamente a lo largo del documento.

## 2. Control de versiones y flujo de trabajo

### 2.1 Repositorio

*Plataforma: GitHub.*

El cliente proporcionó un repositorio base con el stack ya confirmado (Rails 8 + Inertia.js + React + Vite, Authentication Zero, shadcn/ui, Kamal para deploy), pensado como punto de partida para proyectos derivados de este starter. A partir de esa base, el equipo creó el repositorio propio del proyecto, `pis-gogrow`, donde se desarrolla el producto.

El repositorio se administra bajo una organización de GitHub, no en una cuenta personal. Esta decisión responde a una limitación real: los repositorios de cuenta personal solo tienen dos niveles de permiso (dueño y colaboradores), sin roles intermedios como Admin asignables a otra persona. Con 16 integrantes en el equipo, depender de una única cuenta personal como administradora del repositorio representaba un punto único de falla para tareas críticas de configuración (branch protection, gestión de accesos, workflows de CI).

### 2.2 Estructura del repositorio

*Decisión: monorepo.*

El proyecto usa Inertia.js junto con Ruby on Rails. Inertia.js no es una aplicación de frontend independiente: vive dentro del proyecto Rails y se sirve desde el mismo servidor. No existe un backend y un frontend separados en términos de aplicaciones, sino un único proyecto Rails que incluye las vistas de React a través de Inertia.js.

Por esta razón, mantener todo en un único repositorio es lo que tiene sentido técnicamente. Separar el código en dos repositorios agregaría complejidad de sincronización sin ningún beneficio real dado el stack elegido.

### 2.3 Estrategia de ramas

*Decisión: GitHub Flow con rama de integración (`develop`).*

El equipo va a trabajar con tres niveles de ramas: `main`, `develop` y ramas de feature. A continuación se explica qué es cada una y cómo se usa.

#### 2.3.1 Las ramas principales

`main` es la rama que representa la última versión entregada y aprobada por el cliente. Todo lo que está en `main` fue revisado, verificado y mergeado de forma deliberada. Nadie trabaja directamente en `main`: los únicos cambios que entran son los merges desde `develop` al cierre de cada iteración.

`develop` es la rama de integración del equipo. Refleja el estado actual de todo el trabajo en progreso durante la iteración. Las ramas de feature se crean a partir de `develop` y se mergean de vuelta a `develop` cuando terminan. Al cierre de la iteración, `develop` se mergea a `main`.

#### 2.3.2 Ramas de feature

Por cada ítem del backlog que se empieza a desarrollar, se crea una rama nueva a partir de `develop`. Esa rama pertenece al desarrollador que está trabajando en ese ítem y nadie más la toca.

El nombre de la rama sigue el formato:

```
feature/<id-del-item>-<descripcion-corta>
```

Por ejemplo:

```
feature/23-login-usuario
feature/47-listado-empleados
```

Cuando el ítem está completo, la rama se mergea a `develop` mediante un Pull Request y luego se elimina. Una rama de feature que ya fue mergeada no tiene más utilidad.

#### 2.3.3 Flujo de trabajo día a día

El flujo de trabajo para desarrollar un ítem del backlog sigue el patrón de GitHub Flow: se crea una rama de feature a partir de `develop`, se trabaja y commitea en ella, se abre un Pull Request hacia `develop`, se revisa por un compañero, y se integra mediante Squash and Merge.

El procedimiento paso a paso (comandos de Git, cómo abrir el Pull Request en la interfaz de GitHub, cómo titular y completar la descripción) está documentado en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md), secciones 2 y 3.

#### 2.3.4 Cierre de iteración: merge a main

Al finalizar cada iteración, cuando el incremento fue verificado internamente, el Responsable de Gestión de la Configuración mergea `develop` a `main` y crea un tag de versión con el formato de fecha definido en la [sección 2.5](#25-versionado-de-entregas). Este tag marca exactamente qué código fue entregado al cliente en esa iteración.

El procedimiento paso a paso está documentado en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md#6-cierre-de-iteración-responsable-de-scm), sección 6.

#### 2.3.5 Pull Requests: la puerta de entrada a develop

Nadie pushea código directamente a `develop`. Todo cambio pasa por un Pull Request, lo que garantiza que al menos otro integrante revisó el código antes de que entre a la rama compartida. Esto tiene dos beneficios concretos: se detectan errores antes de que afecten al resto del equipo, y las decisiones técnicas quedan documentadas en el historial del repositorio.

#### 2.3.6 Worktrees: trabajar en varios ítems en paralelo

Como técnica opcional de productividad, el equipo puede usar Git worktrees para revisar el Pull Request de un compañero sin perder el trabajo en progreso propio. El procedimiento está documentado en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md#51-revisar-el-pr-de-un-compañero-sin-perder-tu-trabajo-worktrees), sección 5.1.

### 2.4 Convenciones de commits

*Decisión: Conventional Commits.*

Los mensajes de commit siguen el estándar Conventional Commits. El formato es:

```
<tipo>(<alcance>): <descripción breve>
```

Los tipos que vamos a usar son:

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Se agrega una funcionalidad nueva. |
| `fix` | Se corrige un bug. |
| `refactor` | Se reorganiza código sin cambiar su comportamiento. |
| `test` | Se agregan o modifican tests. |
| `docs` | Se modifica documentación. |
| `chore` | Tareas de mantenimiento (dependencias, configuración, etc.). |
| `style` | Cambios de formato que no afectan la lógica. |

El alcance es opcional y describe qué parte del sistema se modificó. Ejemplos completos:

- `feat(auth): agregar login con email y contraseña`
- `fix(empleados): corregir filtro de búsqueda por nombre`
- `refactor(db): extraer lógica de consultas a un service object`
- `test(auth): agregar tests de integración para el login`
- `docs(scm): actualizar estrategia de ramas`

Usar esta convención hace que el historial de commits sea legible de un vistazo y permite saber exactamente qué tipo de cambio introdujo cada commit sin necesidad de abrir el diff.

### 2.5 Versionado de entregas

*Decisión: versionado por fecha, pendiente de confirmación con el cliente.*

Al cierre de cada iteración se crea un tag en Git sobre la rama `main` que identifica la versión entregada. El formato del tag es la fecha de la entrega:

```
v2025-11-03
v2025-11-17
```

Este formato es simple e intuitivo: con solo mirar el tag se sabe exactamente cuándo fue hecha esa entrega.

### 2.6 Verificación automática de la convención de commits

*Decisión:* se agrega un chequeo automático que valida que el título del Pull Request siga el formato de Conventional Commits ([sección 2.4](#24-convenciones-de-commits)), dado que ese título es el que efectivamente queda como mensaje del commit en `develop` tras el Squash and Merge ([sección 2.3.4](#234-cierre-de-iteración-merge-a-main)).

El chequeo se implementa mediante GitHub Actions y se complementa con la configuración del mensaje de commit por defecto del repositorio. El detalle de configuración está documentado en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md#7-configuración-de-checks-automáticos-y-branch-protection-responsable-de-scm).

Este chequeo está activo en el repositorio real (`pis-gogrow`) desde 04/08/2026, configurado como status check obligatorio en la protección de rama de `develop` ([sección 2.7](#27-protección-de-ramas-branch-protection)).

### 2.7 Protección de ramas (branch protection)

*Decisión:* se configuran reglas de protección de rama sobre `main` y `develop`, con alcance distinto en cada una según su rol en el flujo ([sección 2.3.1](#231-las-ramas-principales)):

- **`develop`:** exige Pull Request con al menos una aprobación y el chequeo de título ([sección 2.6](#26-verificación-automática-de-la-convención-de-commits)) como status check obligatorio antes de poder mergear. Esta es la rama por la que pasa todo el trabajo del equipo, así que requiere revisión activa.
- **`main`:** no exige Pull Request (dado que el cierre de iteración se hace mediante merge directo del Responsable de SCM, [sección 2.3.4](#234-cierre-de-iteración-merge-a-main), no mediante PR). En su lugar, restringe quién puede pushear directamente a la rama, limitándolo a los integrantes con rol Admin ([sección 2.1](#21-repositorio)). Así se evita que cualquier otro colaborador pushee código sin pasar por el proceso de iteración, sin bloquear el propio mecanismo de cierre que ya está documentado.

El detalle de configuración está documentado en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md#73-branch-protection-sobre-main-y-develop).

### 2.8 Plantilla de Pull Request

*Decisión:* se define una plantilla estándar para la descripción de los Pull Requests, de forma que toda propuesta de cambio incluya el mismo mínimo de información (qué se hizo, cómo probarlo, ítem relacionado).

El contenido de la plantilla se detalla en la [Guía de Trabajo con el Repositorio](guia-trabajo-repositorio.md#33-completar-la-plantilla-del-pr), sección 3.3.

La plantilla está implementada en [`.github/pull_request_template.md`](../.github/pull_request_template.md).

## 3. Entorno de desarrollo local

Para el entorno de desarrollo local se ofrecen dos opciones. *La opción recomendada es la A.*

El repositorio base incluye un `Dockerfile` multi-stage pensado para producción (usado por Kamal), pero no un entorno preparado para desarrollo local. El equipo agregó dos archivos nuevos para cubrir ese caso: `Dockerfile.dev` (imagen de un solo stage, con todas las gemas de desarrollo y sin precompilar assets) y `docker-compose.yml`, que orquesta un contenedor para Rails + Vite y otro para PostgreSQL. El detalle de ambos archivos está documentado en la [Guía Docker](guia-docker.md).

### Opción A (recomendada): Docker Compose

Se levanta el entorno completo usando Docker Compose: un contenedor para el servidor Rails y otro para la base de datos PostgreSQL. El entorno es idéntico en todas las máquinas del equipo y se levanta con un único comando:

```bash
docker compose up
```

Las ventajas principales son que no hay que instalar Ruby, Rails ni PostgreSQL directamente en cada máquina, y que el entorno es reproducible: lo que funciona en la máquina de un integrante va a funcionar igual en las del resto. Si alguien incorpora una dependencia nueva o cambia algo de configuración, con hacer pull y volver a levantar Docker alcanza.

El único costo es que Docker consume más RAM que la instalación directa. Para máquinas con 8 GB o más no representa un problema en la práctica.

El repositorio incluye los archivos de configuración necesarios (`Dockerfile.dev` y `docker-compose.yml`) para que cualquier integrante pueda levantar el entorno desde cero con un único comando.

### Opción B: instalación local directa

Cada integrante instala Ruby, Rails, Node.js y PostgreSQL directamente en su máquina.

Es más liviano en recursos, pero existe el riesgo de inconsistencias entre entornos: diferencias de versiones o de configuración local que hagan que algo funcione en una máquina y no en otra. Requiere más coordinación manual entre integrantes cada vez que hay un cambio de configuración.

## 4. Ambientes

*Decisión: un único ambiente desplegado en AWS (producción).*

El equipo va a mantener dos ambientes: el entorno local de cada desarrollador y un ambiente de producción desplegado en AWS.

Al cierre de cada iteración, el incremento verificado se despliega al ambiente de producción en AWS. Ese es el ambiente que el cliente usa para revisar el sistema y dar feedback. La URL de producción es la que se comparte con el cliente al finalizar cada iteración.

No se va a mantener un ambiente de staging separado. La rama `develop` actúa como punto de integración del equipo, y la verificación interna se hace en los entornos locales antes de mergear a `main` y hacer el deploy. Agregar un ambiente de staging sumaría complejidad de infraestructura sin un beneficio proporcional para el tamaño y ritmo de este proyecto.

El cliente confirmó AWS como plataforma de infraestructura obligatoria para el ambiente de producción; no se evalúan alternativas de PaaS como Heroku, aunque el repositorio base la soporte como opción de scaffolding.

El mecanismo específico de despliegue hacia AWS (por ejemplo, Kamal, incluido en el repositorio base, frente a un proceso manual de configuración) es una decisión pendiente de definir por el equipo. Esta sección se actualizará con el detalle de esa decisión una vez tomada, y el procedimiento operativo correspondiente quedará documentado en la Guía de Trabajo con el Repositorio.

El acceso a la infraestructura de AWS (creación de la cuenta, gestión de usuarios IAM para los integrantes del equipo) queda pendiente de coordinación interna.

## 5. Gestión de secretos

*Decisión: variables de entorno con archivo `.env` local.*

Las credenciales y valores sensibles se manejan a través de dos mecanismos distintos, según su naturaleza:

**Variables de entorno** (archivo `.env` local, nunca subido al repositorio): valores de configuración de la app y de servicios externos (Sentry, autenticación de paneles internos, login con Google). El repositorio incluye [`.env.example`](../.env.example) con la estructura esperada:

```
VITE_APP_NAME="Rails Inertia Base"
VITE_SENTRY_DSN=dsn
RAILS_SENTRY_DSN=dsn
MISSION_CONTROL_JOBS_HTTP_BASIC_AUTH_USER=admin
MISSION_CONTROL_JOBS_HTTP_BASIC_AUTH_PASSWORD=change-me
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

**Credenciales encriptadas de Rails:** el secreto principal de la aplicación (usado para firmar sesiones y tokens) se maneja con el sistema propio de Rails, no como variable de entorno. Como el proyecto parte de una plantilla compartida, cada equipo debe generar su propia clave la primera vez que configura el proyecto, en vez de reutilizar una heredada de la plantilla base. Esto evita que distintos proyectos derivados del mismo starter terminen compartiendo el mismo secreto. El procedimiento paso a paso para generar esta clave queda documentado en la Guía de Trabajo con el Repositorio.

**Excepción:** las credenciales de PostgreSQL para el entorno de desarrollo local (usuario y contraseña) están definidas directamente en `docker-compose.yml`, no en `.env`. No se consideran secreto porque el ambiente no es accesible fuera de la máquina de cada integrante y el valor es el mismo para todo el equipo: no protegen ningún dato sensible ni un ambiente expuesto.

## 6. Herramientas de gestión del proyecto

### 6.1 Gestión del backlog: ClickUp

El backlog del proyecto se gestiona en ClickUp. Ahí se registran los ítems de trabajo, se asignan responsables, se hace seguimiento del estado de cada tarea y se planifican las iteraciones. Es el punto central de coordinación del trabajo del equipo.

### 6.2 Comunicación interna: Slack

La comunicación entre integrantes del equipo se realiza a través de Slack. Se usa para coordinación del día a día, resolución de dudas, compartir valores de variables de entorno y cualquier comunicación que no requiera una reunión formal.

## Cambios de versiones

| Versión | Fecha | Cambios |
|---|---|---|
| v1.0 | 19/08/2026 | Versión inicial del documento. |
| v2.0 | 29/08/2026 | Se agregan las secciones 2.6 (Verificación automática de la convención de commits), 2.7 (Protección de ramas) y 2.8 (Plantilla de Pull Request). Se corrige la definición de la rama `main` en la sección 2.3.1: se reemplaza «aprobado por el cliente» por una definición que refleja que la aprobación del cliente es posterior al merge y retroalimenta la iteración siguiente, resolviendo la contradicción con el flujo descrito en 2.3.4 y en la sección 4 (Ambientes). El detalle operativo y de configuración (comandos de Git, pasos de configuración en GitHub) se traslada a la Guía de Trabajo con el Repositorio v1.0, dejando en esta guía únicamente el nivel de decisión y una referencia cruzada. Se agrega esta sección de historial de cambios. |
| v3.0 | 02/09/2026 | Se actualiza la sección 2.1 para reflejar que el equipo creó el repositorio real del proyecto (`pis-gogrow`) a partir del repositorio base del cliente. Se actualiza la sección 3 para reflejar la creación de `Dockerfile.dev` y `docker-compose.yml` para el entorno de desarrollo local. Se agrega una excepción en la sección 5 sobre las credenciales de PostgreSQL en desarrollo. Se documenta la migración del repositorio a una organización de GitHub y la asignación de dos integrantes con rol Admin (sección 2.1). Se confirma la implementación del chequeo de Conventional Commits (sección 2.6). Se detalla que la protección de rama difiere entre `develop` (PR + aprobación + status check) y `main` (restricción de push por rol, sin PR obligatorio) en la sección 2.7. Se confirma la implementación de la plantilla de Pull Request (sección 2.8). |
