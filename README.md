# Prototipo: Login con Google para el rol Proveedor

## Cómo funciona

- `/sign_in` muestra únicamente el botón "Continuar con Google" — es la única forma de entrar.
- Al autenticarse, el sistema busca o crea el `User` a partir del email de la cuenta de Google.
- Si esa cuenta todavía no tiene un perfil `Provider` vinculado, se lo crea automáticamente en el mismo login.
- Redirige a `/dashboard/provider`, que sólo deja entrar a un `User` que tenga un `Provider` asociado — cualquier otra cuenta es redirigida de vuelta a `/dashboard`.
- El login por email/password sigue existiendo en el backend (rutas `/sign_in` vía POST, `/sign_up`, reset de password) pero no se muestra en la pantalla de login.
- Sólo se puede loguear con cuentas de Google cuyo dominio esté permitido — por default `gmail.com` y `gogrow.com` (variable `GOOGLE_ALLOWED_DOMAINS`, opcional, ver más abajo). Cualquier otro dominio es rechazado sin crear cuenta.

## Cómo correrlo

Requiere Docker Desktop activo. No hace falta instalar Ruby, Node ni Postgres — todo corre en contenedores.

1. Crear las credenciales OAuth en [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → Create Credentials → OAuth client ID (tipo **Web application**):
   - Authorized JavaScript origins: `http://localhost:3001`
   - Authorized redirect URIs: `http://localhost:3001/auth/google_oauth2/callback`
2. Copiar `.env.example` a `.env` y completar:
   ```
   GOOGLE_CLIENT_ID=<client id del paso anterior>
   GOOGLE_CLIENT_SECRET=<client secret del paso anterior>
   ```
   `.env` está en `.gitignore`: nunca se commitea.

   Opcional — para restringir a otros dominios en vez de `gmail.com,gogrow.com`, agregar:
   ```
   GOOGLE_ALLOWED_DOMAINS=midominio.com,otrodominio.com
   ```
3. Levantar el proyecto:
   ```bash
   docker compose up --build
   ```
4. Abrir <http://localhost:3001> y tocar "Continuar con Google".

Para inspeccionar lo que quedó creado:

```bash
docker compose exec web bin/rails console
User.last.provider
```
