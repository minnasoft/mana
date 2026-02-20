# mana

Minimal Phoenix API focused on GraphQL.

## setup

```bash
nix develop
cp .env.example .env
mix deps.get
mix ecto.create
mix ecto.migrate
```

## postgres

```bash
docker compose up -d postgres
```

## run

```bash
mix phx.server
```

GraphQL endpoint:
- `POST /api/graphql`

Example query:

```graphql
{ health }
```

## quality

Everything runs via Nix shell and flake-managed hooks.

```bash
mix lint
mix test
pre-commit run --all-files
```
