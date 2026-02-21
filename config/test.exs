import Config

config :logger, level: :warning

config :mana, Mana.Repo,
  username: System.get_env("MANA_DB_USER", "mana"),
  password: System.get_env("MANA_DB_PASSWORD", "mana"),
  hostname: System.get_env("MANA_DB_HOST", "localhost"),
  database: "mana_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :mana, ManaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5FoYY6KGjJslPPGuWJYQyENME8vWK7ZicxuDqVdKR5tbiij65YbM9dI0VfPc7vTW",
  server: false

config :mana, Oban,
  repo: Mana.Repo,
  testing: :manual,
  plugins: false,
  queues: false

config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true
