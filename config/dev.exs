import Config

config :logger, :default_formatter, format: "[$level] $message\n"

# Configure your database
config :mana, Mana.Repo,
  username: System.get_env("MANA_DB_USER", "mana"),
  password: System.get_env("MANA_DB_PASSWORD", "mana"),
  hostname: System.get_env("MANA_DB_HOST", "localhost"),
  database: System.get_env("MANA_DB_NAME", "mana_dev"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: String.to_integer(System.get_env("MANA_DB_POOL_SIZE", "10"))

config :mana, ManaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4000"))],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "KMwn9F9sJe3EN1ViW5nC8q13RBE5/3g/ozeIPqOI92SxDiZAKeMRW3wVJ0Fygp4F",
  watchers: []

config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20
