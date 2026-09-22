# Luxur PMS

Single-clinic Patient Management System. Flutter frontend, PocketBase
backend/DB, Cloudflare R2 for files. See `.claude/skills/pms-project/SKILL.md`
(once merged) and `docs/reference/` for the full requirements, workflows and
15-day roadmap — this file only covers day-to-day local setup.

## Prerequisites

- Flutter (stable channel)
- [Node.js](https://nodejs.org/) 18+ (used only for the dev data seed script)

## Local backend setup (once per machine)

The production VPS isn't available yet, so every developer runs their own
local PocketBase instance. Schema is defined in `pocketbase/pb_migrations/`
and is version-controlled and shared; the actual database
(`pocketbase/pb_data/`) is per-machine and gitignored.

```bash
# 1. Download the pinned PocketBase binary for your OS
powershell -File scripts/setup_pocketbase.ps1     # Windows
bash scripts/setup_pocketbase.sh                  # macOS/Linux

# 2. Start it — this automatically applies every migration in pb_migrations/
cd pocketbase
./pocketbase.exe serve      # Windows
./pocketbase serve          # macOS/Linux

# 3. In a separate terminal, create your local superuser (admin dashboard login)
./pocketbase.exe superuser upsert you@local.test YourPassword123!

# 4. Seed sample data (patients, one account per role, sessions, bills, ...)
cd ..
node scripts/seed_dev_data.mjs
```

PocketBase's dashboard is then at `http://127.0.0.1:8090/_/`. Seeded app
logins (all roles) use password `DevPass123!` — e.g. `admin@luxurpms.local`,
`doctor@luxurpms.local`, `hr@luxurpms.local`, `chairman@luxurpms.local`,
`telecaller@luxurpms.local`.

### Changing the schema

Never hand-edit collections only through the dashboard and forget to export
them — that leaves other developers' databases out of sync. Instead:

```bash
cd pocketbase
./pocketbase.exe migrate create <name>
# hand-edit the generated pb_migrations/<timestamp>_<name>.js, then:
./pocketbase.exe migrate up
```

Commit the new migration file. Everyone else picks up the schema change
automatically the next time they run `pocketbase serve` (or `migrate up`).

## Running the Flutter app

Configuration is environment-based via `--dart-define-from-file` — never
hard-code a PocketBase URL in source.

```bash
# against your local PocketBase (default)
flutter run --dart-define-from-file=env/local.json

# against production, once the VPS/domain exist and env/prod.json is filled
# in from env/prod.json.example (prod.json itself is gitignored — never commit it)
flutter run --dart-define-from-file=env/prod.json
```

## Repo layout

```
lib/                    Flutter app
pocketbase/
  pb_migrations/        schema migrations — COMMITTED
  pb_hooks/              server-side rule enforcement (e.g. role-escalation guard) — COMMITTED
  pb_data/                local runtime DB — gitignored, per-machine
  pocketbase(.exe)        downloaded binary — gitignored, per-machine
scripts/
  setup_pocketbase.*      downloads the pinned PocketBase binary
  seed_dev_data.mjs       populates sample data on a LOCAL/DEV instance only
env/
  local.json              committed, safe localhost defaults
  prod.json.example       template — copy to prod.json (gitignored) once VPS exists
docs/reference/           client requirements, workflows, roadmap, UI reference
```
