# GoGrow: gestión del beneficio de viandas

Aplicación web para que GoGrow gestione de punta a punta el beneficio de viandas de su equipo: pedidos, subsidios, consumo y pagos, en un solo lugar para empleados, RR.HH. y proveedores de comida.

Proyecto de Ingeniería de Software 2026 · Facultad de Ingeniería, UdelaR · Grupo 2.

## El problema

GoGrow subsidia el 50 % del costo de las viandas de cada empleado y trabaja con dos proveedores: **TuViandita** y **Endulzate by Noe**. Hoy, al terminar cada mes, se comparte una planilla de Google Sheets con el consumo de cada persona, y cada empleado transfiere lo que debe a GoGrow y a los proveedores.

Ese proceso:

- **demora la conciliación**, y cuando alguien deja la empresa sin haber pagado sus viandas, esa plata se pierde;
- **carga de trabajo manual** a RR.HH. y a los empleados, con riesgo de errores, pagos omitidos y disputas;
- **expone información sensible**: en la planilla compartida se ve quién pagó y quién no.

## Qué hace la app

Cada usuario entra con un rol y ve solamente lo que le corresponde:

| Rol | Qué puede hacer |
|---|---|
| **Empleado** | Elegir viandas para fechas específicas, omitir días y ver en privado su consumo, su subsidio y lo que debe |
| **Proveedor** | Publicar menús, administrar sus platos y ver los pedidos recibidos |
| **RR.HH. / Admin** | Configurar proveedores, reglas de subsidio y ventanas de pedidos, y consultar reportes consolidados |

Los subsidios se aplican automáticamente al hacer el pedido, y el sistema envía recordatorios de fechas límite y de pagos. El alcance completo, incluidas las cuponeras y las funcionalidades opcionales (reseñas y pasarela de pagos), está en la [propuesta del proyecto](docs/propuesta-proyecto.md).

## Objetivos del MVP

1. **Reducir la carga administrativa:** automatizar la conciliación de consumos, el seguimiento de pagos y los reportes que hoy RR.HH. hace a mano.
2. **Optimizar el ciclo de pagos:** mostrar consumo y estado de pagos en tiempo real, para que la mayoría regularice dentro del mes y no haya pérdidas por atrasos.
3. **Mejorar la experiencia del empleado:** darle a cada persona visibilidad clara y privada de lo que consumió, del subsidio y de lo que debe, con recordatorios automáticos.
4. **Aumentar la previsibilidad financiera:** centralizar los datos para que GoGrow pueda proyectar y controlar el gasto del beneficio.

## Stack

| Capa | Tecnología |
|---|---|
| Backend | Ruby 4.0 · Rails 8.1 |
| Frontend | Inertia.js · React 19 · TypeScript · Vite |
| Interfaz | shadcn/ui · Tailwind CSS v4 ([catálogo de componentes](COMPONENTS.md)) |
| Base de datos | PostgreSQL 17, con Solid Queue, Solid Cache y Solid Cable |
| Autenticación | Login con Google (OmniAuth) y roles por sesión |
| Despliegue | AWS. El repo incluye Kamal; el mecanismo de despliegue todavía no está definido ([guía SCM](docs/guia-scm.md#4-ambientes)) |

## Levantar el proyecto

Requiere Docker Desktop; no hace falta instalar Ruby, Node ni PostgreSQL.

```bash
git clone https://github.com/PIS-gogrow/pis-gogrow.git
cd pis-gogrow
cp .env.example .env        # los valores reales se piden por Slack
docker compose up --build
```

La app queda en <http://localhost:3001>. Para cargar los usuarios y datos de prueba, corré una sola vez `docker compose exec web bin/rails db:seed`.

La instalación de Docker, la verificación y los problemas comunes están en la [Guía Docker](docs/guia-docker.md).

## Documentación

| Documento | Para qué sirve |
|---|---|
| [Guía de Trabajo con el Repositorio](docs/guia-trabajo-repositorio.md) | El día a día: ramas, commits, Pull Requests y revisión |
| [Guía SCM](docs/guia-scm.md) | Qué se decidió sobre versionado, ramas, ambientes y secretos, y por qué |
| [Guía Docker](docs/guia-docker.md) | Instalar y usar el entorno de desarrollo local |
| [Propuesta del proyecto](docs/propuesta-proyecto.md) | Contexto, objetivos y alcance definidos por GoGrow |
| [Componentes de UI](COMPONENTS.md) | Qué componente usar en cada pantalla |
| [AGENTS.md](AGENTS.md) | Convenciones del código, para personas y agentes de IA |
| [Decisiones pendientes](docs/desiciones/toDo.md) | Temas abiertos del entorno Docker |
