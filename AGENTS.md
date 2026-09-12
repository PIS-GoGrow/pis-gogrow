# AGENTS.md / CLAUDE.md

This file provides guidance to Coding Agents (like claude.ai/code) when working with code in this repository.

## Project

GoGrow's meal-benefit app: employees order subsidized meals from two food providers, providers publish menus, and HR reconciles consumption and payments. The product and its goals are in `README.md` and `docs/propuesta-proyecto.md`. In code the roles are `consumer` (employee), `provider` and `admin` (HR).

The UI, PR titles, PR descriptions and the team's docs are in Spanish. Process docs live in `docs/`: `guia-trabajo-repositorio.md` (branches, commits, PRs), `guia-scm.md` (the decisions behind them) and `guia-docker.md` (local environment).

## Stack

Rails 8.1 + Inertia.js + React 19 + TypeScript, from the [Inertia Rails React Starter Kit](https://github.com/inertia-rails/react-starter-kit). PostgreSQL with solid_cache / solid_queue / solid_cable on the primary database. Vite builds from `app/javascript`. shadcn/ui + Tailwind v4. Sign-in is Google-only (OmniAuth) on top of a hand-rolled, Authentication Zero style session layer.

## Commands

The team runs everything through Docker Compose (`docs/guia-docker.md`): the app is on http://localhost:3001, and the commands below run inside the `web` container, e.g. `docker compose exec web bin/rspec`.

```bash
docker compose up --build                  # rails + vite + postgres
bin/ci                                     # full local pipeline (config/ci.rb)

bin/rspec spec/requests/users_spec.rb:12   # one example; drop :12 for the file
bin/rubocop                                # -a to autocorrect
npm run lint:fix / format:fix / check      # eslint / prettier / tsc

bin/rails typelizer:generate:refresh       # after touching a serializer or route
bundle exec i18n export                    # after editing config/locales
bin/rails db:seed                          # one user per role; not idempotent, run once on an empty db
```

## Conventions that will surprise you

**Actions render without `render inertia:`.** Controllers inherit `InertiaController`, which includes `Alba::Inertia::Controller` and overrides `default_render`. The component comes from the controller/action path, and the props come from `{Namespace}::{Controller}{Action}Serializer` — instantiated with `view_assigns`, so **instance variables are the props**. `@sessions = ...` becomes the `sessions` its serializer reads. Do not add `render inertia: { ... }`; that's the plain Inertia Rails pattern, not this one. `Provider::MenusController` still uses it — don't copy it from there.

A missing page serializer is **silently ignored** — the page renders with only shared props. Empty props almost always means a misnamed serializer.

**Serializers** live in `app/serializers` with a `*Serializer` suffix (not `app/resources`/`*Resource`, which the vendored skills describe). Three kinds: entity (`UserSerializer`), page (one per action), and `SharedPropsSerializer`, injected globally. Never `as_json` — it bypasses type generation.

**Two generated trees are checked in**, from Typelizer: `app/javascript/types/serializers/` and `app/javascript/routes/` (typed route helpers — use them over URL strings). Regenerate and commit; never hand-edit — CI fails if any of them drift. Outside development the generator needs `TYPELIZER=true`, or explicit `typelize` annotations silently degrade to `unknown`. Same for `app/javascript/components/ui/` (shadcn) and `app/javascript/locales/` (i18n export).

**Translations start in Rails.** `config/locales/en.yml` is the source; i18n-js exports it to `app/javascript/locales/en.json`, which i18next reads. Add a key there, not a string in a component. `flash`, `validations` and `user_mailer` are excluded from the export because the server resolves them. i18next is configured for Rails' `%{name}` placeholders, so one syntax works on both sides.

**A brand-new dependency will fail to install.** `Gemfile` sets `cooldown: 7` and `.npmrc` sets `min-release-age=7`, refusing versions published in the last week. The package isn't broken, it's too new — wait, or bypass with `npm install --min-release-age=0`. `engine-strict=true` also hard-fails outside Node >= 24 / npm >= 11.10.

**Auth**: `Current` holds `session` and delegates `user`. `ApplicationController` authenticates every request from a signed cookie; opt out with `skip_before_action :authenticate`. On validation failure, controllers redirect back with `inertia: { errors: @record.errors }` — PRG, not `render`.

**Sign-in is Google-only, and a user needs a profile to get in.** `OmniauthCallbacksController` finds or creates the `User` by email (domains limited by `GOOGLE_ALLOWED_DOMAINS`, default `gmail.com,gogrow.com`) but never creates a `Provider`, `Consumer` or `Admin`; without one of those the login is rejected with "Rol no disponible". The chosen role is stored on `Session` (`enum :role`) and reaches the frontend as `auth.session.role`. Each role area is a namespace (`Provider::`, `Consumer::`, `Admin::`) whose `InertiaController` runs `authenticate_provider` / `authenticate_consumer` / `authenticate_admin`; put new role screens there. The starter's email/password routes still exist, but nothing links to them and they don't set a role. Local OAuth needs `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` in `.env`, with `http://localhost:3001/auth/google_oauth2/callback` as the authorized redirect URI; restart `web` after changing `.env`.

**SSR is on** (`ssr_enabled` in `config/initializers/inertia_rails.rb`), served by the `:inertia_ssr` Puma plugin. Production images need `--build-arg SSR_ENABLED=true`.

`VITE_*` variables are compiled into the bundle, so they must be set at build time, not runtime — for Kamal, under `builder.secrets` in `config/deploy.yml`.

## Frontend

`@/*` → `app/javascript/*`. `entrypoints/inertia.tsx` wraps everything in `PersistentLayout` (flash toasts, locale sync); pages then choose `AppLayout` or `AuthLayout`.

Forms use Inertia's `<Form>` / `useForm`, wired by `name` — never react-hook-form. The React Compiler runs via Babel in `vite.config.ts`, so skip manual memoization.

**Read `COMPONENTS.md` before building UI.** It says which component to use for each case, lists what isn't installed yet, and maps the team's React prototype (Base UI, CSS Modules, native `Select`) onto this repo's shadcn setup — code copied from the prototype has to be rewritten, not pasted. A role's navigation is the `navItems` list in `components/app-sidebar.tsx`.

## Testing

RSpec, request and mailer specs. **Fixtures, not factories** (`fixtures :users`), though factory_bot is available. `sign_in(user)` comes from `spec/support/authentication_helpers.rb`.

Use the `inertia_rails/rspec` matchers (`render_component`, `have_props`, `have_flash`) rather than reading `inertia.props`. After a POST/PATCH/DELETE that redirects, `follow_redirect!` before asserting on props or flash.

## Style

**Comments are the exception, not the habit.** Write one only for a non-obvious *why*, a constraint, or a genuine footgun. Never narrate what the code says, and never put design rationale in a comment — that belongs in the commit message. If a comment is questioned in review, delete it. Leave existing comments alone.

Prefer the smallest idiomatic solution and framework defaults over hand-rolled machinery. Don't extract a constant unless it's genuinely reused across files or names an opaque value — pass enum and inclusion lists straight to the macro. `frozen_string_literal` is cop-enforced, so never hoist a string just to freeze it.

RuboCop inherits `rubocop-rails-omakase` with cops re-enabled in `.rubocop.yml`, two of them against omakase's intent: indentation is `normal` (methods after `private` are *not* extra-indented), and `Style/StringLiterals` covers every file, not just `test/`.

Declaration order — models: constants → attr macros → enums → associations → validations → callbacks → scopes. Serializers: `typelize_from` → attributes → typed attributes → associations, each `typelize` directly above what it types. Components: imports (let `lint:fix` sort them) → props interface → default export.

## Pull requests

Full procedure in `docs/guia-trabajo-repositorio.md`. Branch off an up-to-date `develop` as `feature/<clickup-id>-<short-description>`, and open the PR against `develop` — never `main`, which only receives the iteration-close merge.

Title: Conventional Commits, `<type>(<scope>): <description>`, with type one of `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`; scope optional; description in Spanish, starting lowercase — `feat(menus): permitir editar un plato`. The `lint-pr-title` check blocks the merge otherwise. PRs are squash-merged with the title as the commit message, so commits inside the branch are free-form.

Body is the four sections of `.github/pull_request_template.md`, in Spanish:

```markdown
## Qué se hizo
## Cómo probarlo
## Ítem relacionado
## Checklist
```

`Ítem relacionado` is the ClickUp item; `Checklist` keeps the template's three boxes, ticked only when true. Active voice, no throat-clearing or filler adjectives. One line per paragraph — don't hard-wrap, the tools reading it wrap for you. `gh pr create --body` bypasses the template, so write the four sections out in full.

## Skills

`.claude/skills/` vendors the [inertia-rails/skills](https://github.com/inertia-rails/skills) set; load `inertia-rails-architecture` first for any new page or feature. Where they conflict, `alba-inertia` wins — with the naming caveat above.
