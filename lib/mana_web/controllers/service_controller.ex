defmodule ManaWeb.ServiceController do
  use ManaWeb, :controller

  alias Mana.Service

  @doc "Returns version information for the API."
  def version(conn, _params) do
    json(conn, %{sha: Service.version()})
  end

  @doc "Returns readiness status based on DB connectivity."
  def readiness(conn, _params) do
    if Service.readiness?() do
      json(conn, %{status: "ok", database: "connected"})
    else
      conn
      |> put_status(:service_unavailable)
      |> json(%{status: "error", database: "disconnected"})
    end
  end
end
