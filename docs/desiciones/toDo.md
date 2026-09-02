# Decisiones pendientes — entorno Docker

## Suite RSpec dentro de Docker

**Estado actual**: [`docker-compose.dev.yml`](../../docker-compose.dev.yml) solo levanta
la app para probarla a mano (navegador / curl), no corre tests.

**Qué falta decidir**: si se quiere correr `bundle exec rspec` dentro de este entorno
(como hace `.github/workflows/ci.yml`), hay que definir:
- Si se corre como comando puntual (`docker compose -f docker-compose.dev.yml run web
  bundle exec rspec`) contra la imagen ya buildeada, o si conviene un servicio/perfil
  de compose dedicado.
- Cómo resetear la base de datos entre corridas repetidas (`db:test:prepare`), ya que
  hoy el `CMD` de [`Dockerfile.dev`](../../Dockerfile.dev) solo corre `db:prepare` una
  vez al bootear.
