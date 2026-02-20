# mana

## dev shell

```bash
nix develop
```

## postgres (docker compose)

```bash
cp .env.example .env
docker compose up -d postgres
```

check status:

```bash
docker compose ps postgres
```

check readiness:

```bash
docker compose exec postgres pg_isready -U "$MANA_DB_USER" -d "$MANA_DB_NAME"
```

connection string is configured in `.env` via `DATABASE_URL`.

If you previously ran a different Postgres image/tag, reset local DB volume before retrying:

```bash
docker compose down -v
docker compose up -d postgres
```
