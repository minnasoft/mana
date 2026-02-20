defmodule Mana.Repo do
  use Ecto.Repo,
    otp_app: :mana,
    adapter: Ecto.Adapters.Postgres
end
