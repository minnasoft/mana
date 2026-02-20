defmodule Mana do
  @moduledoc "Public service helpers for the API."

  alias Mana.Service

  @doc "Returns current git version SHA."
  @spec version() :: String.t()
  defdelegate version(), to: Service

  @doc "Returns service status: ok or error."
  @spec status() :: String.t()
  defdelegate status(), to: Service
end
