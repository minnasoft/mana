# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Migration safety checks
config :excellent_migrations,
  # postgres supports concurrent index operations; keep all checks enabled
  skip_checks: []

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure the endpoint
config :mana, ManaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ManaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mana.PubSub

config :mana,
  ecto_repos: [Mana.Repo],
  generators: [timestamp_type: :utc_datetime],
  discord_user_id: System.get_env("DISCORD_USER_ID")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
