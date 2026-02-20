defmodule ManaWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mana

  plug Plug.Static,
    at: "/",
    from: :mana,
    gzip: not code_reloading?,
    only: ManaWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :mana
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug ManaWeb.Router
end
